(ns overlay
  (:require [babashka.fs :as fs]
            [babashka.process :as process]
            [clojure.string :as str]))

(def repo-name "riru")

(defn find-repo-root []
  (loop [dir (fs/path (System/getProperty "user.dir"))]
    (cond
      (fs/exists? (fs/path dir "bb.edn")) dir
      (nil? (fs/parent dir)) (fs/path (System/getProperty "user.dir"))
      :else (recur (fs/parent dir)))))

(defn gentoo-repo-path []
  (-> (process/sh "portageq" "get_repo_path" "/" "gentoo")
      :out
      str/trim))

(defn repositories-configuration [overlay-path]
  (str "[gentoo]\nlocation = " (gentoo-repo-path)
       "\n\n[" repo-name "]\nlocation = " overlay-path
       "\nmasters = gentoo\n"))

(defn run-egencache!
  ([overlay-path] (run-egencache! overlay-path nil))
  ([overlay-path atoms]
   (let [args (cond-> ["egencache"
                       "--repositories-configuration"
                       (repositories-configuration overlay-path)
                       "--repo" repo-name
                       "--update"]
               (seq atoms) (into atoms))
         {:keys [out err exit]} (apply process/sh args)]
     (when (seq out) (print out))
     (when (seq err) (binding [*out* *err*] (print err)))
     (when (pos? exit)
       (System/exit exit)))))
