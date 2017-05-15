{-# LANGUAGE TemplateHaskell, FlexibleInstances #-}

module MonoDistrMapReduce (distrMapReduce, __remoteTable) where

import Data.Map (Map)
import qualified Data.Map as Map (size, toList)
import Control.Monad (forM_, replicateM, replicateM_)
import Control.Distributed.Process
import Control.Distributed.Process.Closure
import MapReduce (MapReduce(..), reducePerKey, groupByKey)

--------------------------------------------------------------------------------
-- Simple distributed implementation                                          --
--------------------------------------------------------------------------------

mapperProcess :: (ProcessId, ProcessId, Closure (MapReduce String String String Int Int))
              -> Process ()
mapperProcess (master, workQueue, mrClosure) = do
    us <- getSelfPid
    mr <- unClosure mrClosure
    go us mr
  where
    go us mr = do
      send workQueue us

      receiveWait
        [ match $ \(key, val) -> send master (mrMap mr key val) >> go us mr
        , match $ \()         -> return ()
        ]

remotable ['mapperProcess]

distrMapReduce :: Closure (MapReduce String String String Int Int)
               -> [NodeId]
               -> Map String String
               -> Process (Map String Int)
distrMapReduce mrClosure mappers input = do
  mr     <- unClosure mrClosure
  master <- getSelfPid

  workQueue <- spawnLocal $ do
    forM_ (Map.toList input) $ \(key, val) -> do
      them <- expect
      send them (key, val)

    replicateM_ (length mappers) $ do
      them <- expect
      send them ()


  forM_ mappers $ \nid -> spawn nid ($(mkClosure 'mapperProcess) (master, workQueue, mrClosure))

  partials <- replicateM (Map.size input) expect

  return (reducePerKey mr . groupByKey . concat $ partials)
