(ns readme-packages
  (:require [babashka.fs :as fs]
            [clojure.string :as str]
            [overlay :as overlay]))

(def begin-marker "# BEGIN GENERATED PACKAGES\n")
(def end-marker "# END GENERATED PACKAGES\n")

(def exclude-top-level
  #{".git"
    ".github"
    "distdir"
    "licenses"
    "metadata"
    "profiles"
    "tasks"})

(def description-re #"^DESCRIPTION=\"((?:\\.|[^\"\\])*)\"\s*$")

(defn find-repo-root []
  (overlay/find-repo-root))

(defn repo-root []
  (overlay/find-repo-root))

(defn readme-path []
  (str (find-repo-root) "/README.org"))

(defn version-chunk [chunk]
  (if (re-matches #"\d+" chunk)
    [:n (parse-long chunk)]
    [:s chunk]))

(defn version-sort-key [version]
  (vec (map version-chunk
            (str/split (-> version
                           (str/replace #"_" "~")
                           (str/replace #"-" "~"))
                       #"[.~]"))))

(defn sort-versions [versions]
  (let [live (filter #(= % "9999") versions)
        stable (remove #(= % "9999") versions)]
    (concat (sort-by version-sort-key stable) live)))

(defn parse-description [ebuild-path]
  (some (fn [line]
          (when-let [[_ description] (re-matches description-re line)]
            (-> description
                (str/replace #"\\n" " ")
                (str/replace #"\\t" " "))))
        (str/split-lines (slurp (str ebuild-path)))))

(defn sanitize-cell [value]
  (-> value
      (str/replace #"\s+" " ")
      str/trim
      (str/replace "|" "/")))

(defn format-table [rows]
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

(defn ebuild-version [package ebuild-path]
  (let [filename (fs/file-name ebuild-path)
        prefix (str package "-")
        suffix ".ebuild"]
    (when (str/starts-with? filename prefix)
      (subs filename (count prefix) (- (count filename) (count suffix))))))

(defn collect-packages
  ([] (collect-packages (repo-root)))
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

(defn render-packages [packages]
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

(defn generated-block [packages]
  (str begin-marker (render-packages packages) end-marker))

(defn quote-pattern [s]
  (str/replace s #"([\\.*+?|^${}()\[\]])" "\\\\$1"))

(defn marker-pattern []
  (re-pattern (str "(?s)"
                   (quote-pattern begin-marker)
                   ".*?"
                   (quote-pattern end-marker))))

(defn patch-readme [readme packages]
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

(defn generate! []
  (collect-packages))

(defn update-readme! []
  (let [readme (readme-path)
        packages (generate!)
        content (slurp readme)
        updated (patch-readme readme packages)]
    (if (= content updated)
      (println "No changes needed for" readme)
      (do (spit readme updated)
          (println "Updated" readme)))))

(defn print-section! []
  (print (render-packages (generate!))))

(defn check-readme! []
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
