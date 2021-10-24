{-# LANGUAGE OverloadedStrings #-}

import Hakyll
import GHC.IO.Encoding

main :: IO ()
main =
  do
    setLocaleEncoding utf8
    setFileSystemEncoding utf8
    setForeignEncoding utf8
    hakyll $ do

      -- -- Bibliography:
      -- match "bib/*" $ compile biblioCompiler

      -- -- Style for bibliography:
      -- match "csl/*" $ compile cslCompiler
      
      -- Get files (copy 'as is')
      match "files/*" $ do
          route idRoute
          compile copyFileCompiler

      -- Get images (copy 'as is')
      match "images/*" $ do
          route idRoute
          compile copyFileCompiler

      -- Get javascript files (copy 'as is')
      match "js/*" $ do
          route idRoute
          compile copyFileCompiler

      -- Compile & compress CSS
      match "css/*" $ do
          route idRoute
          compile compressCssCompiler

      -- tags <- buildTags "posts/*" (fromCapture "tags/*.html")

      -- match "posts/*.md" $ parsePosts tags "csl/aims-press.csl" "bib/refs.bib"
      match "index.md" parseMd
      match "publications.md" parseMd
      -- match "books.md" parseMd
      -- match "blog.html" parseBlog

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
postCtx = dateField "date" "%Y-%m-%d" <> defaultContext

parsePosts :: Tags -> String -> String -> Rules ()
parsePosts tags bib style = do
  route $ setExtension "html"
  compile $ do
    let postCtxWithTags tags = tagsField "tags" tags <> postCtx

    pandocBiblioCompiler bib style
      >>= loadAndApplyTemplate "templates/post.html" (postCtxWithTags tags)
      >>= saveSnapshot "content" -- Snapshot for the atom.xml file
      >>= loadAndApplyTemplate "templates/default.html" (postCtxWithTags tags)
      >>= relativizeUrls

parseBlog :: Rules ()
parseBlog = do
  route idRoute
  compile $ do
    let postList dir sortFilter = do
          posts   <- sortFilter =<< loadAll dir
          itemTpl <- loadBody "templates/post-item.html"
          applyTemplateList itemTpl postCtx posts
    let indexCtx = field "posts" $ \_ -> postList "posts/*" $ fmap (take 9999) . recentFirst

    getResourceBody
      >>= applyAsTemplate indexCtx
      >>= loadAndApplyTemplate "templates/default.html" postCtx
      >>= relativizeUrls

parseMd :: Rules ()
parseMd = do
  route $ setExtension "html"
  compile $
    pandocCompiler
    >>= loadAndApplyTemplate "templates/default.html" postCtx
    >>= relativizeUrls

-- Config for the Atom.xml file.
myFeedConfiguration :: FeedConfiguration
myFeedConfiguration =
  FeedConfiguration {
    feedTitle       = "Philippe Desjardins-Proulx's blog",
    feedDescription = "Machine Learning, Mathematics, Typed Lambda-Calculi, Probabilistic Programming, Technology, etc etc...",
    feedAuthorName  = "Philippe Desjardins-Proulx",
    feedAuthorEmail = "philippe.desjardins.proulx@umontreal.ca",
    feedRoot        = "https://phdp.github.io/"
  }

