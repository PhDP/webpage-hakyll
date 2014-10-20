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

            -- Compile & compress CSS
            match "css/*" $ do
                route idRoute
                compile compressCssCompiler

            -- Parse html files
            match "posts/*.html" $ parsePosts
            match "posts-fr/*.html" $ parsePosts
            match "posts-jp/*.html" $ parsePosts
            match "index.html" $ parseHtml
            match "contact.html" $ parseHtml
            match "writings.html" $ parseHtml
            match "writings-fr.html" $ parsePostList "posts-fr/*"
            match "writings-jp.html" $ parsePostList "posts-jp/*"

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
    dateField "date" "%Y.%m.%d" `mappend`
    defaultContext

postList :: Pattern -> ([Item String] -> Compiler [Item String]) -> Compiler String
postList dir sortFilter = do
    posts   <- sortFilter =<< loadAll dir
    itemTpl <- loadBody "templates/post-item.html"
    list    <- applyTemplateList itemTpl postCtx posts
    return list

parsePostList p = do
    route idRoute
    compile $ do
        let indexCtx = field "posts" $ \_ -> (postList p) $ fmap (take 30) . recentFirst
        getResourceBody
            >>= applyAsTemplate indexCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

parsePosts = do
    route idRoute
    compile $ do
        getResourceBody
            >>= loadAndApplyTemplate "templates/post.html" postCtx
            >>= saveSnapshot "content" -- Snapshot for the atom.xml file
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

parseHtml = do
    route idRoute
    compile $ do
        let indexCtx = field "posts" $ \_ -> (postList "posts/*") $ fmap (take 30) . recentFirst
        getResourceBody
           >>= applyAsTemplate indexCtx
           >>= loadAndApplyTemplate "templates/default.html" postCtx
           >>= relativizeUrls

-- Config for the Atom.xml file.
myFeedConfiguration :: FeedConfiguration
myFeedConfiguration =
    FeedConfiguration {
        feedTitle       = "Philippe Desjardins-Proulx -- Posts",
        feedDescription = "Artificial Intelligence, Machine Learning, Programming, Technology, et cetera...",
        feedAuthorName  = "Philippe Desjardins-Proulx",
        feedAuthorEmail = "philippe.d.proulx@gmail.com",
        feedRoot        = "http://phdp.github.io/"
    }
