(ns overlay
  "Filesystem helpers for locating the riru overlay repository root."
  (:require [babashka.fs :as fs]))

(defn find-repo-root
  "Walk up from `user.dir` until `bb.edn` is found.

  Returns the overlay root path, or `user.dir` when no `bb.edn` ancestor exists."
  []
  (loop [dir (fs/path (System/getProperty "user.dir"))]
    (cond
      (fs/exists? (fs/path dir "bb.edn")) dir
      (nil? (fs/parent dir)) (fs/path (System/getProperty "user.dir"))
      :else (recur (fs/parent dir)))))
