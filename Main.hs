{-# LANGUAGE OverloadedStrings #-}

import Data.Monoid (mappend)
import Hakyll
import GHC.IO.Encoding

main :: IO ()
main =
  do
    setLocaleEncoding utf8
    setFileSystemEncoding utf8
    setForeignEncoding utf8
    hakyll $ do

      -- Get files (copy 'as is')
      match "files/*" $ do
          route idRoute
          compile copyFileCompiler

      -- Get images (copy 'as is')
      match "images/*" $ do
          route idRoute
          compile copyFileCompiler

      match "bib/*" $ compile biblioCompiler

      match "csl/*" $ compile cslCompiler

      -- Get javascript files (copy 'as is')
      match "js/*" $ do
          route idRoute
          compile copyFileCompiler

      -- Compile & compress CSS
      match "css/*" $ do
          route idRoute
          compile compressCssCompiler

      tags <- buildTags "posts/*" (fromCapture "tags/*.html")

      match "posts/*.md" $ parsePosts tags "csl/alpha.csl" "bib/refs.bib"
      match "index.md" $ parseMd
      match "publications.md" $ parseMd
      match "blog.html" $ parseBlog

      -- Parse templates
      match "templates/*" $ compile templateCompiler

      -- Built the atom.xml file
      create ["atom.xml"] $ do
        route idRoute
        compile $ do
          let feedCtx = postCtx `mappend` bodyField "description"
          posts <- fmap (take 10) . recentFirst =<<
            loadAllSnapshots "posts/*" "content"
          renderAtom myFeedConfiguration feedCtx posts

-- Format for posts
postCtx :: Context String
postCtx =
  dateField "date" "%Y-%m-%d" `mappend`
  defaultContext

postCtxWithTags :: Tags -> Context String
postCtxWithTags tags = tagsField "tags" tags `mappend` postCtx

postList :: Pattern -> ([Item String] -> Compiler [Item String]) -> Compiler String
postList dir sortFilter = do
  posts   <- sortFilter =<< loadAll dir
  itemTpl <- loadBody "templates/post-item.html"
  list    <- applyTemplateList itemTpl postCtx posts
  return list

parsePosts tags bib style = do
  route $ setExtension "html"
  compile $ do
    pandocBiblioCompiler bib style
      >>= loadAndApplyTemplate "templates/post.html" (postCtxWithTags tags)
      >>= saveSnapshot "content" -- Snapshot for the atom.xml file
      >>= loadAndApplyTemplate "templates/default.html" (postCtxWithTags tags)
      >>= relativizeUrls

parseBlog = do
  route idRoute
  compile $ do
    let indexCtx = field "posts" $ \_ -> (postList "posts/*") $ fmap (take 9999) . recentFirst
    getResourceBody
      >>= applyAsTemplate indexCtx
      >>= loadAndApplyTemplate "templates/default.html" postCtx
      >>= relativizeUrls

parseMd = do
  route $ setExtension "html"
  compile $ do
    pandocCompiler
      >>= loadAndApplyTemplate "templates/default.html" postCtx
      >>= relativizeUrls

-- Config for the Atom.xml file.
myFeedConfiguration :: FeedConfiguration
myFeedConfiguration =
  FeedConfiguration {
    feedTitle       = "Philippe Desjardins-Proulx's blog",
    feedDescription = "Machine Learning, Programming, Technology, Philosophy, et cetera...",
    feedAuthorName  = "Philippe Desjardins-Proulx",
    feedAuthorEmail = "philippe.desjardins.proulx@umontreal.ca",
    feedRoot        = "https://phdp.github.io/"
  }
