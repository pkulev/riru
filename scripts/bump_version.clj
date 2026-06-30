(ns bump-version
  "Copy an ebuild to a new version and refresh its Manifest and README entry.

  Invoked via `bb bump:version` or `bb -m bump-version`."
  (:require [babashka.cli :as cli]
            [babashka.fs :as fs]
            [babashka.process :as process]
            [clojure.string :as str]
            [overlay :as overlay]
            [readme-packages :as readme]))

(defn parse-atom
  "Parse a package atom such as `dev-lang/hy` into `{:category … :package …}`."
  [atom]
  (let [[category package] (str/split (str/trim atom) #"/" 2)]
    (when (and category package
               (not (str/blank? category))
               (not (str/blank? package)))
      {:category category :package package})))

(defn package-dir
  "Return the filesystem path for `category/package` under the overlay root."
  [{:keys [category package]}]
  (fs/path (overlay/find-repo-root) category package))

(defn ebuild-filename
  "Return the ebuild filename for `package` at `version`."
  [package version]
  (str package "-" version ".ebuild"))

(defn ebuild-path
  "Return the absolute path to `category/package/package-version.ebuild`."
  [category package version]
  (fs/path (package-dir {:category category :package package})
           (ebuild-filename package version)))

(defn list-versions
  "List all ebuild versions for `category/package`, sorted Gentoo-style."
  [category package]
  (let [prefix (str package "-")
        suffix ".ebuild"]
    (->> (fs/glob (package-dir {:category category :package package}) "*.ebuild")
         (map fs/file-name)
         (keep (fn [filename]
                 (when (str/starts-with? filename prefix)
                   (subs filename (count prefix) (- (count filename) (count suffix))))))
         readme/sort-versions)))

(defn latest-version
  "Return the highest sorted version for `category/package`, or nil."
  [category package]
  (last (list-versions category package)))

(defn resolve-base-version
  "Use explicit `base` when provided, otherwise the latest overlay version."
  [category package base]
  (let [base (some-> base str/trim)]
    (cond
      (seq base) base
      :else (latest-version category package))))

(defn parse-issue-body
  "Extract bump parameters from a GitHub version-bump issue body.

  Expects `### Package atom`, `### New version`, and optional `### Base version`
  headings as produced by the issue form template."
  [body]
  (when (seq body)
    (let [atom (some-> (re-find #"(?m)^### Package atom\s*\r?\n\s*(\S+)" body) second str/trim)
          version (some-> (re-find #"(?m)^### New version\s*\r?\n\s*(\S+)" body) second str/trim)
          base (some-> (re-find #"(?m)^### Base version[^\n]*\r?\n\s*(\S+)" body) second str/trim)]
      (when (and atom version)
        (cond-> {:atom atom :version version}
          (seq base) (assoc :base base))))))

(defn run-manifest!
  "Run `ebuild … manifest` for `ebuild`, optionally using `distdir`."
  [ebuild distdir]
  (let [ebuild (str ebuild)
        root (str (overlay/find-repo-root))
        {:keys [exit out err]} (process/sh "ebuild" ebuild "manifest"
                                            {:dir root
                                             :env (cond-> {"PORTDIR_OVERLAY" root}
                                                    distdir (assoc "DISTDIR" distdir))})]
    (when (seq out) (print out))
    (when (seq err) (binding [*out* *err*] (print err)))
    (when (pos? exit)
      (println "ebuild manifest failed for" ebuild)
      (System/exit exit))))

(defn bump!
  "Copy an ebuild to a new version and optionally refresh Manifest and README.

  `opts` must include `:atom` and `:version`. Recognized keys:
  `:base`, `:distdir`, `:dry-run`, `:skip-manifest`, `:skip-readme`.

  Returns a map describing the bump on success; throws on invalid input."
  [opts]
  (let [{:keys [atom version base distdir]} opts
        dry-run? (:dry-run opts)
        skip-manifest? (:skip-manifest opts)
        skip-readme? (:skip-readme opts)
        {:keys [category package]} (or (parse-atom atom)
                                       (throw (ex-info "Invalid package atom" {:atom atom})))
        base-ver (resolve-base-version category package base)
        _ (when-not base-ver
            (throw (ex-info "No base ebuild found" {:atom atom})))
        src (ebuild-path category package base-ver)
        dst (ebuild-path category package version)]
    (when-not (fs/exists? src)
      (throw (ex-info "Base ebuild not found" {:path (str src) :version base-ver})))
    (when (fs/exists? dst)
      (throw (ex-info "Target ebuild already exists" {:path (str dst)})))
    (println "Bumping" atom "from" base-ver "to" version)
    (println "  copy" (str src) "->" (str dst))
    (when dry-run?
      (println "Dry run: skipping manifest and README update"))
    (when-not dry-run?
      (fs/copy src dst)
      (when-not skip-manifest?
        (run-manifest! dst distdir))
      (when-not skip-readme?
        (readme/update-readme!)))
    {:atom atom
     :category category
     :package package
     :base base-ver
     :version version
     :ebuild (str dst)}))

(def cli-spec
  "babashka.cli option spec for [[-main]]."
  {:help {:alias :h :desc "Show help" :coerce :boolean}
   :pkg-atom {:desc "Package atom (category/package)"}
   :version {:desc "New package version"}
   :base {:desc "Base version to copy (default: latest in overlay)"}
   :distdir {:desc "DISTDIR for ebuild manifest"}
   :dry-run {:desc "Show actions without writing files" :coerce :boolean}
   :skip-manifest {:desc "Do not run ebuild manifest" :coerce :boolean}
   :skip-readme {:desc "Do not regenerate README.org" :coerce :boolean}
   :issue-body {:desc "Parse bump request from a GitHub issue body"}})

(defn normalize-cli-args
  "Recover from Babashka task parsing, which strips `--atom` and leaves the
  package atom as the first positional argument."
  [args]
  (if (and (seq args)
           (not (str/starts-with? (str (first args)) "--"))
           (parse-atom (first args)))
    (into ["--pkg-atom" (first args)] (rest args))
    args))

(defn -main
  "CLI entry point for `bb -m bump-version` and the `bump:version` task."
  [& args]
  (let [args (normalize-cli-args args)
        {:keys [opts]} (cli/parse-args args {:spec cli-spec})
        {:keys [help issue-body pkg-atom]} opts
        opts (cond-> opts
               pkg-atom (assoc :atom pkg-atom))]
    (when help
      (println "Usage: bb bump:version --pkg-atom category/package --version NEW [--base VER] [--dry-run]")
      (println "       bb bump:version --issue-body \"...\"")
      (System/exit 0))
    (let [params (if issue-body
                   (merge (parse-issue-body issue-body)
                          (select-keys opts [:distdir :dry-run :skip-readme :skip-manifest]))
                   opts)]
      (when-not (:atom params)
        (println "Missing --pkg-atom (or package atom as first arg) or parseable issue body")
        (System/exit 1))
      (when-not (:version params)
        (println "Missing --version or parseable issue body")
        (System/exit 1))
      (bump! params))))
