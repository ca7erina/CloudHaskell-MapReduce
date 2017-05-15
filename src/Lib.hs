module Lib
    ( wordCount
    ) where

import System.Environment (getArgs)
import System.IO
import Control.Applicative
import Control.Monad
import System.Random
import Control.Distributed.Process
import Control.Distributed.Process.Node (initRemoteTable)
import Control.Distributed.Process.Backend.SimpleLocalnet
import Data.Map (Map)
import Data.Array (Array, listArray)
import qualified Data.Map as Map (fromList)

import qualified CountWords
import qualified PolyDistrMapReduce
import qualified MonoDistrMapReduce

import System.Directory
import Data.List

rtable :: RemoteTable
rtable = PolyDistrMapReduce.__remoteTable
       . MonoDistrMapReduce.__remoteTable
       . CountWords.__remoteTable
       $ initRemoteTable

wordCount :: IO ()
wordCount = do
  args <- getArgs

  case args of
    -- Local word count
    "local" : "count" : files -> do
      putStrLn "Starting single node locally"
      input <- constructInput files
      print $ CountWords.localCountWords input

    -- Distributed word count
    "master" : host : port : "count" : files -> do
      putStrLn "Starting Node as Manager"
      input   <- constructInput files
      backend <- initializeBackend host port rtable
      startMaster backend $ \slaves -> do
        result <- CountWords.distrCountWords slaves input
        liftIO $ print result

    -- Generic worker for distributed examples
    "worker" : host : port : [] -> do
      putStrLn "Starting Node as Worker"
      backend <- initializeBackend host port rtable
      startSlave backend


constructInput :: [FilePath] -> IO (Map FilePath CountWords.Document)
constructInput dir = do
  let basePath = getBasePath $ head dir
  allFile <- getDirectoryContents basePath
  let txtFile = filter (isSuffixOf ".txt") allFile
  let listFilePath = map (basePath ++ ) txtFile

  contents <- mapM readFile $ listFilePath
  return . Map.fromList $ zip listFilePath contents

getBasePath :: FilePath -> FilePath
getBasePath base = base ++ "/"

arrayFromList :: [e] -> Array Int e
arrayFromList xs = listArray (0, length xs - 1) xs
