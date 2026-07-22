(ns bump-crates
  "Build and publish a Gentoo cargo crate tarball for a Rust package bump.

  Invoked via `bb bump:crates` or `bb -m bump-crates`.

  Resolves expanded SRC_URI from Gentoo md5-cache (after pmaint regen).
  Uploads ${P}-crates.tar.xz to the fixed riru 1.0.0 release."
  (:require [babashka.cli :as cli]
            [babashka.fs :as fs]
            [babashka.http-client :as http]
            [babashka.process :as process]
            [bump-version :as bump]
            [clojure.java.io :as io]
            [clojure.string :as str]
            [overlay :as overlay]
            [readme-packages :as readme]))

(def release-tag "1.0.0")

(defn die!
  "Print `msgs` to stderr and exit with status 1."
  [& msgs]
  (binding [*out* *err*]
    (apply println msgs))
  (System/exit 1))

(defn require-bin!
  "Exit unless `bin` is on PATH."
  [bin]
  (when-not (fs/which bin)
    (die! "Required command not found on PATH:" bin)))

(defn sh!
  "Run `args` (string sequence) in optional `dir`; print output; exit on failure."
  [args & {:keys [dir]}]
  (let [cmd (mapv str args)
        opts (cond-> {}
               dir (assoc :dir (str dir)))
        result (if (seq opts)
                 (apply process/sh opts cmd)
                 (apply process/sh cmd))
        {:keys [exit out err]} result]
    (when (seq out) (print out))
    (when (seq err) (binding [*out* *err*] (print err)))
    (when (pos? exit)
      (die! "Command failed (" exit "):" (str/join " " cmd)))
    result))

(defn default-distdir
  "Return `$ROOT/distdir`."
  []
  (str (fs/path (overlay/find-repo-root) "distdir")))

(defn md5-cache-path
  "Path to md5-cache metadata for `category`/`package`-`version`."
  [category package version]
  (fs/path (overlay/find-repo-root) "metadata" "md5-cache" category
           (str package "-" version)))

(defn regen-md5-cache!
  "Refresh overlay md5-cache via `pmaint regen` when possible."
  []
  (when-not (fs/which "pmaint")
    (println "Warning: pmaint not found; using existing md5-cache"))
  (when (fs/which "pmaint")
    (println "Regenerating md5-cache…")
    (let [root (str (overlay/find-repo-root))
          {:keys [exit out err]} (process/sh {:dir root} "pmaint" "regen" ".")]
      (when (seq out) (print out))
      (when (seq err) (binding [*out* *err*] (print err)))
      (when (pos? exit)
        (println "Warning: pmaint regen failed; falling back to existing md5-cache")))))

(defn read-src-uri-from-cache
  "Return expanded SRC_URI string from md5-cache, or nil."
  [category package version]
  (let [cache (md5-cache-path category package version)]
    (when (fs/exists? cache)
      (some (fn [line]
              (when (str/starts-with? line "SRC_URI=")
                (subs line (count "SRC_URI="))))
            (str/split-lines (slurp (str cache)))))))

(defn parse-src-uri-entries
  "Parse an expanded SRC_URI line into [{:url … :filename …} …].

  Handles `url`, `url -> filename`, and space-separated entries."
  [src-uri]
  (when (seq src-uri)
    (let [tokens (str/split (str/trim src-uri) #"\s+")]
      (loop [toks tokens
             acc []]
        (if (empty? toks)
          acc
          (let [url (first toks)
                more (next toks)]
            (if (and (seq more) (= "->" (first more)) (seq (next more)))
              (recur (nnext more)
                     (conj acc {:url url :filename (second more)}))
              (recur more
                     (conj acc {:url url
                                :filename (fs/file-name url)})))))))))

(defn source-entry
  "Pick the upstream source archive entry (not *-crates.tar.xz)."
  [entries p]
  (let [candidates (filter (fn [{:keys [filename]}]
                             (and filename
                                  (not (str/ends-with? filename "-crates.tar.xz"))
                                  (or (= filename (str p ".tar.gz"))
                                      (= filename (str p ".tar.xz"))
                                      (= filename (str p ".tar.bz2"))
                                      (= filename (str p ".tgz"))
                                      (re-matches (re-pattern (str p "\\.(tar\\.(gz|xz|bz2)|tgz)"))
                                                  filename))))
                           entries)]
    (or (first candidates)
        (first (remove #(str/includes? (:filename %) "-crates.") entries)))))

(defn resolve-source!
  "Resolve upstream source {:url :filename} via md5-cache SRC_URI."
  [category package version]
  (regen-md5-cache!)
  (let [src-uri (or (read-src-uri-from-cache category package version)
                    (die! "No SRC_URI in md5-cache for"
                          (str category "/" package "-" version)
                          "(is this a cargo ebuild?)"))
        entries (parse-src-uri-entries src-uri)
        p (str package "-" version)
        entry (or (source-entry entries p)
                  (die! "Could not find source archive in SRC_URI:" src-uri))]
    (println "Source:" (:url entry) "->" (:filename entry))
    entry))

(defn download!
  "Download `url` to `dest` unless it already exists."
  [url dest]
  (if (fs/exists? dest)
    (println "Already present:" (str dest))
    (do
      (println "Downloading" url)
      (fs/create-dirs (fs/parent dest))
      (let [resp (http/get url {:as :stream :throw false})]
        (when-not (<= 200 (:status resp) 299)
          (die! "Download failed (" (:status resp) "):" url))
        (with-open [in (:body resp)
                    out (io/output-stream (str dest))]
          (io/copy in out))))))

(defn archive-top-dir
  "Return the top-level directory name inside a tar archive."
  [archive]
  (let [{:keys [out]} (process/sh "tar" "-tf" (str archive))
        first-line (some-> out str/split-lines first)]
    (when-not first-line
      (die! "Empty archive:" (str archive)))
    (-> first-line
        (str/replace #"/.*" "")
        str/trim)))

(defn unpack-archive!
  "Unpack `archive` into `distdir`; return absolute path to source root."
  [archive distdir]
  (let [top (archive-top-dir archive)
        dest (fs/path distdir top)]
    (println "Unpacking" (fs/file-name archive) "→" top)
    (sh! ["tar" "-C" (str distdir) "-xf" (str archive)])
    (when-not (fs/exists? dest)
      (die! "Expected source directory missing after unpack:" (str dest)))
    (str dest)))

(defn run-pycargoebuild!
  "Run pycargoebuild -c -i on `ebuild` with sources in `src-dir`."
  [ebuild src-dir distdir]
  (require-bin! "pycargoebuild")
  (println "Building crate tarball with pycargoebuild…")
  (sh! ["pycargoebuild" "-c" "-f" "-d" (str distdir) "-i" (str ebuild) (str src-dir)]
       :dir (overlay/find-repo-root)))

(defn github-repo-from-remote
  "Parse owner/repo from `git remote get-url origin`, or nil."
  []
  (try
    (let [{:keys [out exit]} (process/sh "git" "remote" "get-url" "origin"
                                          {:dir (str (overlay/find-repo-root))})]
      (when (zero? exit)
        (let [url (str/trim out)]
          (or (second (re-find #"github\.com[:/]([^/]+/[^/.]+)" url))
              (second (re-find #"github\.com/([^/]+/[^/.]+)" url))))))
    (catch Exception _ nil)))

(defn upload-crates!
  "Upload crate tarball to the fixed riru release tag."
  [crates-tarball repo]
  (require-bin! "gh")
  (let [repo (or repo (github-repo-from-remote) "pkulev/riru")]
    (println "Uploading" (fs/file-name crates-tarball)
             "to" (str repo "@" release-tag) "…")
    (sh! ["gh" "release" "upload" release-tag (str crates-tarball)
          "--clobber" "-R" repo]
         :dir (overlay/find-repo-root))))

(defn bump-crates!
  "Build, upload, and manifest a crate tarball for an existing ebuild version.

  `opts` must include `:atom` and `:version`. Recognized keys:
  `:distdir`, `:repo`, `:dry-run`, `:skip-upload`, `:skip-manifest`, `:skip-readme`."
  [opts]
  (let [{:keys [atom version repo]} opts
        dry-run? (:dry-run opts)
        skip-upload? (:skip-upload opts)
        skip-manifest? (:skip-manifest opts)
        skip-readme? (:skip-readme opts)
        distdir (or (some-> (:distdir opts) str)
                    (default-distdir))
        {:keys [category package]} (or (bump/parse-atom atom)
                                       (die! "Invalid package atom:" atom))
        ebuild (bump/ebuild-path category package version)
        p (str package "-" version)
        crates-name (str p "-crates.tar.xz")
        crates-path (fs/path distdir crates-name)]
    (when-not (fs/exists? ebuild)
      (die! "Ebuild not found:" (str ebuild)))
    (println "Crate bump for" (str category "/" package "-" version))
    (fs/create-dirs distdir)
    (let [{:keys [url filename]} (resolve-source! category package version)
          archive (fs/path distdir filename)]
      (when dry-run?
        (println "Dry run: would download" url)
        (println "Dry run: would run pycargoebuild -c -i")
        (when-not skip-upload?
          (println "Dry run: would upload" crates-name "to release" release-tag))
        (when-not skip-manifest?
          (println "Dry run: would run pkgdev manifest"))
        (when-not skip-readme?
          (println "Dry run: would refresh README.org"))
        (System/exit 0))
      (download! url archive)
      (let [src-dir (unpack-archive! archive distdir)]
        (run-pycargoebuild! ebuild src-dir distdir)
        (when-not (fs/exists? crates-path)
          (die! "Expected crate tarball missing:" (str crates-path)))
        (when-not skip-upload?
          (upload-crates! crates-path repo))
        (when-not skip-manifest?
          (require-bin! "pkgdev")
          (println "Updating Manifest…")
          (bump/run-manifest! ebuild distdir))
        (when-not skip-readme?
          (readme/update-readme!))
        {:atom atom
         :category category
         :package package
         :version version
         :ebuild (str ebuild)
         :crates (str crates-path)}))))

(def cli-spec
  "babashka.cli option spec for [[-main]]."
  {:help {:alias :h :desc "Show help" :coerce :boolean}
   :pkg-atom {:desc "Package atom (category/package)"}
   :version {:desc "Package version whose ebuild already exists"}
   :distdir {:desc "DISTDIR (default: $ROOT/distdir)"}
   :repo {:desc "GitHub owner/repo for release upload (default: origin remote)"}
   :dry-run {:desc "Show actions without writing files" :coerce :boolean}
   :skip-upload {:desc "Do not upload to the 1.0.0 GitHub release" :coerce :boolean}
   :skip-manifest {:desc "Do not run pkgdev manifest" :coerce :boolean}
   :skip-readme {:desc "Do not regenerate README.org" :coerce :boolean}})

(defn -main
  "CLI entry point for `bb -m bump-crates` and the `bump:crates` task."
  [& args]
  (let [args (bump/normalize-cli-args args)
        {:keys [opts]} (cli/parse-args args {:spec cli-spec})
        {:keys [help pkg-atom]} opts
        opts (cond-> opts
               pkg-atom (assoc :atom pkg-atom))]
    (when help
      (println "Usage: bb bump:crates --pkg-atom category/package --version VER [options]")
      (println
       (format "  Builds ${P}-crates.tar.xz via pycargoebuild, uploads to riru release %s,"
               release-tag))
      (println "  then regenerates Manifest and README.")
      (println "Options: --distdir --repo --dry-run --skip-upload --skip-manifest --skip-readme")
      (System/exit 0))
    (when-not (:atom opts)
      (die! "Missing --pkg-atom (or package atom as first arg)"))
    (when-not (:version opts)
      (die! "Missing --version"))
    (bump-crates! opts)))
