(ns overlay
  (:require [babashka.fs :as fs]))

(defn find-repo-root []
  (loop [dir (fs/path (System/getProperty "user.dir"))]
    (cond
      (fs/exists? (fs/path dir "bb.edn")) dir
      (nil? (fs/parent dir)) (fs/path (System/getProperty "user.dir"))
      :else (recur (fs/parent dir)))))
