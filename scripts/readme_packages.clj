(ns readme-packages
  "Generate and validate the package index section in README.org."
  (:require [babashka.fs :as fs]
            [clojure.string :as str]
            [overlay :as overlay]))

(def begin-marker
  "Org-mode marker delimiting the start of the generated package table."
  "# BEGIN GENERATED PACKAGES\n")

(def end-marker
  "Org-mode marker delimiting the end of the generated package table."
  "# END GENERATED PACKAGES\n")

(def exclude-top-level
  "Top-level overlay directories that are not Gentoo package categories."
  #{".git"
    ".github"
    "distdir"
    "licenses"
    "metadata"
    "profiles"
    "tasks"})

(def description-re
  "Regex matching a DESCRIPTION= line in an ebuild header."
  #"^DESCRIPTION=\"((?:\\.|[^\"\\])*)\"\s*$")


(defn readme-path
  "Absolute path to README.org in the overlay root."
  []
  (str (overlay/find-repo-root) "/README.org"))

(defn version-chunk
  "Classify a Gentoo version component for sorting.

  Numeric chunks sort before non-numeric ones at the same position."
  [chunk]
  (if (re-matches #"\d+" chunk)
    [:n (parse-long chunk)]
    [:s chunk]))

(defn version-sort-key
  "Return a comparable key for Gentoo version strings."
  [version]
  (vec (map version-chunk
            (str/split (-> version
                           (str/replace #"_" "~")
                           (str/replace #"-" "~"))
                       #"[.~]"))))

(defn sort-versions
  "Sort version strings using Gentoo ordering; live ebuilds (`9999`) come last."
  [versions]
  (let [live (filter #(= % "9999") versions)
        stable (remove #(= % "9999") versions)]
    (concat (sort-by version-sort-key stable) live)))

(defn parse-description
  "Read the DESCRIPTION field from an ebuild file."
  [ebuild-path]
  (some (fn [line]
          (when-let [[_ description] (re-matches description-re line)]
            (-> description
                (str/replace #"\\n" " ")
                (str/replace #"\\t" " "))))
        (str/split-lines (slurp (str ebuild-path)))))

(defn sanitize-cell
  "Normalize text for safe inclusion in a markdown table cell."
  [value]
  (-> value
      (str/replace #"\s+" " ")
      str/trim
      (str/replace "|" "/")))

(defn format-table
  "Render package rows as a pipe-delimited markdown table with aligned columns."
  [rows]
  (let [headers ["Name" "Version(s)" "Description"]
        widths (mapv (fn [idx]
                       (apply max
                              (count (nth headers idx))
                              (map #(count (nth % idx)) rows)))
                     (range 3))
        pad-row (fn [cells]
                  (format "| %s | %s | %s |"
                          (format (str "%-" (nth widths 0) "s") (nth cells 0))
                          (format (str "%-" (nth widths 1) "s") (nth cells 1))
                          (format (str "%-" (nth widths 2) "s") (nth cells 2))))
        separator (format "|%s+%s+%s|"
                          (apply str (repeat (+ (nth widths 0) 2) "-"))
                          (apply str (repeat (+ (nth widths 1) 2) "-"))
                          (apply str (repeat (+ (nth widths 2) 2) "-")))]
    (into [(pad-row headers) separator]
          (map pad-row rows))))

(defn ebuild-version
  "Extract the version suffix from `package-VERSION.ebuild`."
  [package ebuild-path]
  (let [filename (fs/file-name ebuild-path)
        prefix (str package "-")
        suffix ".ebuild"]
    (when (str/starts-with? filename prefix)
      (subs filename (count prefix) (- (count filename) (count suffix))))))

(defn collect-packages
  "Scan the overlay for ebuilds and return a nested map:

  `{category {package {:versions \"…\" :description \"…\"}}}`"
  ([] (collect-packages (overlay/find-repo-root)))
  ([root]
   (let [root-path (fs/path root)]
     (reduce
      (fn [acc category-path]
        (let [category (fs/file-name category-path)]
          (if (or (not (fs/directory? category-path))
                  (contains? exclude-top-level category))
            acc
            (reduce
             (fn [acc' package-path]
               (if-not (fs/directory? package-path)
                 acc'
                 (let [package (fs/file-name package-path)
                       ebuilds (sort (fs/glob package-path "*.ebuild"))]
                   (if (empty? ebuilds)
                     acc'
                     (let [version-data (keep (fn [ebuild]
                                                (when-let [version (ebuild-version package ebuild)]
                                                  [version (parse-description ebuild)]))
                                              ebuilds)
                           versions (sort-versions (map first version-data))
                           descriptions (into {} version-data)
                           description (or (get descriptions (last versions))
                                           (some #(get descriptions %)
                                                 (reverse versions))
                                           "")]
                       (assoc-in acc' [category package]
                                 {:versions (str/join ", " versions)
                                  :description description}))))))
             acc
             (sort (fs/list-dir category-path))))))
      {}
      (sort (fs/list-dir root-path))))))

(defn render-packages
  "Format collected package data as org-mode sections with markdown tables."
  [packages]
  (str (str/join "\n"
                 (mapcat (fn [category]
                           (let [rows (for [[package {:keys [versions description]}]
                                          (sort (get packages category))]
                                       [package versions (sanitize-cell description)])]
                             (concat [(str "** " category)]
                                     (format-table rows)
                                     [""])))
                         (sort (keys packages))))
       "\n"))

(defn generated-block
  "Wrap rendered package output with README.org index markers."
  [packages]
  (str begin-marker (render-packages packages) end-marker))

(defn quote-pattern
  "Escape `s` for safe inclusion in a regular expression."
  [s]
  (str/replace s #"([\\.*+?|^${}()\[\]])" "\\\\$1"))

(defn marker-pattern
  "Regex matching the generated package block between README.org markers."
  []
  (re-pattern (str "(?s)"
                   (quote-pattern begin-marker)
                   ".*?"
                   (quote-pattern end-marker))))

(defn patch-readme
  "Replace the marked package index in `readme` with freshly generated content.

  Exits with status 1 when the markers are missing."
  [readme packages]
  (let [content (slurp readme)
        block (generated-block packages)]
    (if-not (and (str/includes? content begin-marker)
                 (str/includes? content end-marker))
      (do
        (binding [*out* *err*]
          (println "README.org is missing package index markers; expected:")
          (print begin-marker)
          (print end-marker)
          (println "Add both markers to README.org and re-run: bb readme:packages"))
        (System/exit 1))
      (str/replace content (marker-pattern) block))))

(defn generate!
  "Collect package metadata from the overlay tree."
  []
  (collect-packages))

(defn update-readme!
  "Regenerate README.org when the package index is out of date.

  Babashka task entry point for `readme:packages`."
  []
  (let [readme (readme-path)
        packages (generate!)
        content (slurp readme)
        updated (patch-readme readme packages)]
    (if (= content updated)
      (println "No changes needed for" readme)
      (do (spit readme updated)
          (println "Updated" readme)))))

(defn print-section!
  "Print the generated package index to stdout.

  Babashka task entry point for `readme:packages:print`."
  []
  (print (render-packages (generate!))))

(defn check-readme!
  "Exit with status 1 when README.org does not match the overlay.

  Babashka task entry point for `readme:packages:check`."
  []
  (let [readme (readme-path)
        content (slurp readme)
        block (generated-block (generate!))]
    (if (and (str/includes? content begin-marker)
             (str/includes? content end-marker))
      (let [current (re-find (marker-pattern) content)]
        (when (or (nil? current) (not= current block))
          (println "README.org package index is out of date; run: bb readme:packages")
          (System/exit 1)))
      (do
        (println "README.org package index is missing; run: bb readme:packages")
        (System/exit 1)))))
