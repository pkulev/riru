(ns metadata-cache
  (:require [babashka.fs :as fs]
            [babashka.process :as process]
            [overlay :as overlay]))

(defn cache-path []
  (fs/path (overlay/find-repo-root) "metadata/md5-cache"))

(defn update-cache! []
  (let [root (str (overlay/find-repo-root))]
    (println "Updating" (str (cache-path)))
    (overlay/run-egencache! root)
    (println "Done.")))

(defn check-cache! []
  (let [root (str (overlay/find-repo-root))
        cache (str (cache-path))
        backup (fs/create-temp-dir "riru-md5-cache-")]
    (try
      (when (fs/exists? cache)
        (fs/copy-tree cache (fs/path backup "md5-cache")))
      (overlay/run-egencache! root)
      (let [{:keys [exit]} (process/sh "diff" "-qr"
                                       (str backup "/md5-cache") cache)]
        (when (pos? exit)
          (println "metadata/md5-cache is out of date; run: bb metadata:cache")
          (System/exit 1)))
      (finally
        (fs/delete-tree backup {:force true})))))
