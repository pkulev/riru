(ns ci
  "CI helpers that emit GitHub Actions step outputs.

  Invoked via `bb ci:bump-params` and `bb ci:parse-bump-pr-title`."
  (:require [babashka.fs :as fs]
            [bump-version :as bump]
            [clojure.string :as str]
            [overlay :as overlay]))

(defn emit-output!
  "Write `kvs` as `key=value` lines to `$GITHUB_OUTPUT`, or stdout if unset."
  [kvs]
  (let [text (->> kvs
                  (map (fn [[k v]] (str (name k) "=" (str v))))
                  (str/join "\n"))]
    (if-let [out (System/getenv "GITHUB_OUTPUT")]
      (spit out (str text "\n") :append true)
      (println text))))

(defn branch-slug
  "Turn `category/package` into a branch-safe slug."
  [atom]
  (str/replace atom "/" "_"))

(defn bump-params!
  "Resolve version-bump parameters for `bump.yml` and emit step outputs.

  Reads either workflow_dispatch inputs (`EVENT_NAME=workflow_dispatch` plus
  `INPUT_ATOM` / `INPUT_VERSION` / `INPUT_BASE`) or a labeled issue
  (`ISSUE_BODY`, `ISSUE_NUMBER`)."
  []
  (let [event (System/getenv "EVENT_NAME")]
    (if (= event "workflow_dispatch")
      (let [atom (System/getenv "INPUT_ATOM")
            version (System/getenv "INPUT_VERSION")
            base (or (System/getenv "INPUT_BASE") "")]
        (when (or (str/blank? atom) (str/blank? version))
          (binding [*out* *err*]
            (println "workflow_dispatch requires INPUT_ATOM and INPUT_VERSION"))
          (System/exit 1))
        (emit-output! {:atom atom
                       :version version
                       :base base
                       :issue ""
                       :branch_slug (branch-slug atom)}))
      (let [body (or (System/getenv "ISSUE_BODY") "")
            issue (or (System/getenv "ISSUE_NUMBER") "")
            {:keys [atom version base]} (or (bump/parse-issue-body body)
                                            {})]
        (when (or (str/blank? atom) (str/blank? version))
          (binding [*out* *err*]
            (println "Failed to parse issue body for package atom and new version"))
          (System/exit 1))
        (emit-output! {:atom atom
                       :version version
                       :base (or base "")
                       :issue issue
                       :branch_slug (branch-slug atom)})))))

(def bump-pr-title-re
  #"^([a-z0-9-]+/[a-zA-Z0-9_+-]+):\s*bump version to\s*(.+)$")

(defn parse-bump-pr-title
  "Parse `category/package: bump version to VERSION` from a PR title."
  [title]
  (when-let [[_ atom version] (re-matches bump-pr-title-re (str/trim (str title)))]
    (let [[category package] (str/split atom #"/" 2)
          ebuild (str category "/" package "/" package "-" version ".ebuild")
          manifest (str category "/" package "/Manifest")]
      {:atom atom
       :version version
       :ebuild ebuild
       :manifest manifest})))

(defn parse-bump-pr-title!
  "Resolve atom/version from `PR_TITLE` for `bump-manifest.yml` and emit outputs.

  Fails if the title does not match or the ebuild is missing in the checkout."
  []
  (let [title (or (System/getenv "PR_TITLE") "")
        parsed (parse-bump-pr-title title)]
    (when-not parsed
      (binding [*out* *err*]
        (println "Could not parse atom/version from PR title:" title))
      (System/exit 1))
    (let [{:keys [ebuild] :as out} parsed
          root (overlay/find-repo-root)
          path (fs/path root ebuild)]
      (when-not (fs/exists? path)
        (binding [*out* *err*]
          (println "Ebuild not found:" ebuild))
        (System/exit 1))
      (emit-output! out))))

(defn -main
  "CLI entry for `bb -m ci <subcommand>`."
  [& args]
  (case (first args)
    "bump-params" (bump-params!)
    "parse-bump-pr-title" (parse-bump-pr-title!)
    (do (binding [*out* *err*]
          (println "Usage: bb -m ci bump-params | parse-bump-pr-title"))
        (System/exit 1))))
