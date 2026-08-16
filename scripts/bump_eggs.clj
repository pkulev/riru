(ns bump-eggs
  "Build and publish CHICKEN egg source tarballs for Portage fetch.

  Invoked via `bb bump:eggs` or `bb -m bump-eggs`.

  Creates ${CHICKEN_EGG}-${PV}.tar.xz and uploads to the fixed riru 1.0.0
  release (same pattern as crate tarballs). Sources come from overlay
  files/, chicken-install cache, or henrietta retrieve."
  (:require [babashka.cli :as cli]
            [babashka.fs :as fs]
            [babashka.process :as process]
            [bump-version :as bump]
            [clojure.string :as str]
            [overlay :as overlay]
            [readme-packages :as readme]))

(def release-tag "1.0.0")

(def chicken-category "dev-chicken")

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
  "Run `args` (string sequence) in optional `dir` / env; print output; exit on failure."
  [args & {:keys [dir extra-env]}]
  (let [cmd (mapv str args)
        opts (cond-> {}
               dir (assoc :dir (str dir))
               (seq extra-env) (assoc :extra-env extra-env))
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

(defn chicken-egg-name
  "Map Portage package name to upstream CHICKEN egg name."
  [package]
  (if (re-matches #"srfi\d+" package)
    (str "srfi-" (subs package (count "srfi")))
    package))

(defn egg-archive-name
  "Return `${egg}-${version}.tar.xz`."
  [egg version]
  (str egg "-" version ".tar.xz"))

(defn files-archive-path
  "Path to vendored archive under package files/, if present."
  [category package egg version]
  (fs/path (overlay/find-repo-root) category package "files"
           (egg-archive-name egg version)))

(defn default-egg-cache
  "Default chicken-install egg cache directory."
  []
  (str (fs/path (System/getProperty "user.home") ".cache" "chicken-install")))

(defn list-chicken-eggs
  "Return [{:category :package :version :egg :ebuild} …] for all/one egg ebuilds."
  [{:keys [atom version]}]
  (let [root (overlay/find-repo-root)]
    (if atom
      (let [{:keys [category package]} (or (bump/parse-atom atom)
                                           (die! "Invalid package atom:" atom))
            _ (when-not (= category chicken-category)
                (die! "Expected category" chicken-category "got" category))
            ver (or version
                    (bump/latest-version category package)
                    (die! "No ebuilds for" atom))
            ebuild (bump/ebuild-path category package ver)]
        (when-not (fs/exists? ebuild)
          (die! "Ebuild not found:" (str ebuild)))
        [{:category category
          :package package
          :version ver
          :egg (chicken-egg-name package)
          :ebuild (str ebuild)}])
      (->> (fs/list-dir (fs/path root chicken-category))
           (filter fs/directory?)
           (map fs/file-name)
           sort
           (mapcat (fn [package]
                     (let [ver (bump/latest-version chicken-category package)]
                       (when ver
                         [{:category chicken-category
                           :package package
                           :version ver
                           :egg (chicken-egg-name package)
                           :ebuild (str (bump/ebuild-path chicken-category
                                                          package ver))}]))))
           (remove nil?)
           vec))))

(def build-artifact-re
  "Basename patterns for chicken-install build leftovers (must not ship)."
  #"(?i).*\.(so|o|link|import\.scm|import\.so|static\.o|build\.sh|install\.sh)$")

(defn build-artifact?
  "True when path looks like a chicken-install build leftover."
  [path]
  (boolean (re-matches build-artifact-re (fs/file-name path))))

(defn scrub-egg-dir!
  "Remove chicken-install build leftovers from `dir` (in place)."
  [dir]
  (doseq [path (fs/glob dir "**")
          :when (and (fs/regular-file? path) (build-artifact? path))]
    (println "Scrubbing build artifact:" (str (fs/relativize dir path)))
    (fs/delete path)))

(defn egg-requires-predefined-types?
  "True when `egg.egg` declares (types-file (predefined))."
  [egg-dir egg]
  (let [egg-file (fs/path egg-dir (str egg ".egg"))]
    (when (fs/exists? egg-file)
      (let [body (slurp (str egg-file))]
        (and (str/includes? body "types-file")
             (str/includes? body "predefined"))))))

(defn validate-egg-sources!
  "Die if predefined .types is declared but missing from `egg-dir`."
  [egg-dir egg]
  (when (egg-requires-predefined-types? egg-dir egg)
    (let [types (fs/path egg-dir (str egg ".types"))]
      (when-not (fs/exists? types)
        (die! "Egg" egg "declares (types-file (predefined)) but"
              (str types) "is missing."
              "\nRefuse to pack polluted/incomplete sources;"
              " use --from-henrietta for a clean retrieve.")))))

(defn prepare-pack-dir!
  "Copy `src-dir` to work-dir, scrub artifacts, validate; return clean dir."
  [src-dir egg work-dir]
  (let [dest (fs/path work-dir "pack" egg)]
    (fs/create-dirs (fs/parent dest))
    (when (fs/exists? dest)
      (fs/delete-tree dest))
    (fs/copy-tree src-dir dest)
    (scrub-egg-dir! dest)
    (validate-egg-sources! dest egg)
    (str dest)))

(defn pack-dir!
  "Create xz tarball of directory `src-dir` at `dest` (flat contents)."
  [src-dir dest]
  (fs/create-dirs (fs/parent dest))
  (when (fs/exists? dest)
    (fs/delete dest))
  (println "Packing" (str src-dir) "→" (fs/file-name dest))
  (sh! ["tar" "-C" (str src-dir) "-cJf" (str dest) "."]))

(defn retrieve-henrietta!
  "Retrieve `egg:version` into a temp chicken-install cache; return egg dir."
  [egg version work-dir]
  (require-bin! "chicken-install")
  (let [cache (fs/path work-dir "egg-cache")
        egg-dir (fs/path cache egg)]
    (fs/create-dirs cache)
    (println "chicken-install -r" (str egg ":" version))
    (sh! ["chicken-install" "-r" (str egg ":" version)]
         :extra-env {"CHICKEN_EGG_CACHE" (str cache)})
    (when-not (fs/directory? egg-dir)
      (die! "Henrietta retrieve did not produce" (str egg-dir)))
    (str egg-dir)))

(defn resolve-source-dir!
  "Resolve clean egg source directory for packing.

  With `:from-henrietta`, always retrieve fresh sources.
  Otherwise: overlay files/ → chicken cache → die (suggest --from-henrietta)."
  [{:keys [category package egg version from-henrietta egg-cache work-dir]}]
  (let [files-arch (files-archive-path category package egg version)
        cache-dir (fs/path (or egg-cache (default-egg-cache)) egg)
        raw (cond
              from-henrietta
              (do
                (println "Fetching clean sources via henrietta")
                (retrieve-henrietta! egg version work-dir))

              (fs/exists? files-arch)
              (let [dest (fs/path work-dir "from-files" egg)]
                (fs/create-dirs dest)
                (println "Using overlay files:" (str files-arch))
                (sh! ["tar" "-C" (str dest) "-xJf" (str files-arch)])
                (str dest))

              (fs/directory? cache-dir)
              (do
                (println "Using chicken cache:" (str cache-dir))
                (str cache-dir))

              :else
              (die! "No egg sources for" egg version
                    "\nTried:" (str files-arch)
                    "\n       " (str cache-dir)
                    "\nPass --from-henrietta to retrieve via chicken-install -r"))]
    {:dir (prepare-pack-dir! raw egg work-dir)}))

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

(defn upload-egg!
  "Upload egg tarball to the fixed riru release tag."
  [tarball repo]
  (require-bin! "gh")
  (let [repo (or repo (github-repo-from-remote) "pkulev/riru")]
    (println "Uploading" (fs/file-name tarball)
             "to" (str repo "@" release-tag) "…")
    (sh! ["gh" "release" "upload" release-tag (str tarball)
          "--clobber" "-R" repo]
         :dir (overlay/find-repo-root))))

(defn bump-one-egg!
  "Pack/upload/manifest one egg entry."
  [entry opts]
  (let [{:keys [category package version egg ebuild]} entry
        {:keys [distdir repo dry-run skip-upload skip-manifest
                from-henrietta egg-cache]} opts
        archive-name (egg-archive-name egg version)
        archive-path (fs/path distdir archive-name)
        work-dir (str (fs/create-temp-dir {:prefix "bump-eggs-"}))]
    (try
      (println "===" (str category "/" package "-" version)
               "(" egg ") ===")
      (if dry-run
        (do
          (println "Dry run: would pack" archive-name)
          (when-not skip-upload
            (println "Dry run: would upload to release" release-tag))
          (when-not skip-manifest
            (println "Dry run: would run pkgdev manifest"))
          {:atom (str category "/" package)
           :egg egg
           :version version
           :archive (str archive-path)
           :dry-run true})
        (let [{:keys [dir]} (resolve-source-dir!
                             {:category category
                              :package package
                              :egg egg
                              :version version
                              :from-henrietta from-henrietta
                              :egg-cache egg-cache
                              :work-dir work-dir})]
          (pack-dir! dir archive-path)
          (when-not skip-upload
            (upload-egg! archive-path repo))
          (when-not skip-manifest
            (require-bin! "ebuild")
            (println "Updating Manifest…")
            (bump/run-manifest! ebuild distdir :force? true))
          {:atom (str category "/" package)
           :egg egg
           :version version
           :archive (str archive-path)}))
      (finally
        (fs/delete-tree work-dir)))))

(defn bump-eggs!
  "Pack and publish egg tarballs.

  Without `:atom`, processes every package under `dev-chicken`.
  Recognized keys: `:atom`, `:version`, `:distdir`, `:repo`, `:dry-run`,
  `:skip-upload`, `:skip-manifest`, `:skip-readme`, `:from-henrietta`,
  `:egg-cache`."
  [opts]
  (let [distdir (or (some-> (:distdir opts) str) (default-distdir))
        opts (assoc opts :distdir distdir)
        entries (list-chicken-eggs opts)]
    (when (empty? entries)
      (die! "No chicken egg ebuilds found under" chicken-category))
    (fs/create-dirs distdir)
    (println (str "Egg bump for " (count entries) " package(s); distdir=" distdir))
    (let [results (mapv #(bump-one-egg! % opts) entries)]
      (when-not (or (:dry-run opts) (:skip-readme opts))
        (readme/update-readme!))
      results)))

(def cli-spec
  "babashka.cli option spec for [[-main]]."
  {:help {:alias :h :desc "Show help" :coerce :boolean}
   :pkg-atom {:desc "Package atom (dev-chicken/…); default: all eggs"}
   :version {:desc "Ebuild version (default: latest for the atom)"}
   :distdir {:desc "DISTDIR (default: $ROOT/distdir)"}
   :repo {:desc "GitHub owner/repo for release upload (default: origin remote)"}
   :egg-cache {:desc "chicken-install cache dir (default: ~/.cache/chicken-install)"}
   :from-henrietta {:desc "Retrieve via chicken-install -r when no files/cache" :coerce :boolean}
   :dry-run {:desc "Show actions without writing files" :coerce :boolean}
   :skip-upload {:desc "Do not upload to the 1.0.0 GitHub release" :coerce :boolean}
   :skip-manifest {:desc "Do not run pkgdev manifest" :coerce :boolean}
   :skip-readme {:desc "Do not regenerate README.org" :coerce :boolean}})

(defn -main
  "CLI entry point for `bb -m bump-eggs` and the `bump:eggs` task."
  [& args]
  (let [args (bump/normalize-cli-args args)
        {:keys [opts]} (cli/parse-args args {:spec cli-spec})
        {:keys [help pkg-atom]} opts
        opts (cond-> opts
               pkg-atom (assoc :atom pkg-atom))]
    (when help
      (println "Usage: bb bump:eggs [--pkg-atom category/package] [--version VER] [options]")
      (println
       (format "  Builds ${CHICKEN_EGG}-${PV}.tar.xz, uploads to riru release %s,"
               release-tag))
      (println "  then force-refreshes Manifest digests (and README unless --skip-readme).")
      (println "  Without --pkg-atom, processes every package under" chicken-category ".")
      (println "Prefer --from-henrietta for release uploads (clean sources + .types).")
      (println "Else: overlay files/ (optional) → chicken cache (scrubbed).")
      (println "Options: --distdir --repo --egg-cache --from-henrietta --dry-run")
      (println "         --skip-upload --skip-manifest --skip-readme")
      (System/exit 0))
    (bump-eggs! opts)))
