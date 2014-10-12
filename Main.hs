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
        
            -- Get posts
            match "posts/*.html" $ do
                route idRoute
                compile $ do
                    getResourceBody
                        >>= loadAndApplyTemplate "templates/post.html" postCtx
                        >>= saveSnapshot "content" -- Snapshot for the atom.xml file
                        >>= loadAndApplyTemplate "templates/default.html" postCtx
                        >>= relativizeUrls

            -- Get French posts
            match "posts-fr/*.html" $ do
                route idRoute
                compile $ do
                    getResourceBody
                        >>= loadAndApplyTemplate "templates/post.html" postCtx
                        >>= loadAndApplyTemplate "templates/default.html" postCtx
                        >>= relativizeUrls

            -- Get Japanese posts
            match "posts-jp/*.html" $ do
                route idRoute
                compile $ do
                    getResourceBody
                        >>= loadAndApplyTemplate "templates/post.html" postCtx
                        >>= loadAndApplyTemplate "templates/default.html" postCtx
                        >>= relativizeUrls
            
            -- Parse html files
            match "index.html" $ do
                route idRoute
                compile $ do
                    let indexCtx = field "posts" $ \_ -> (postList "posts/*") $ fmap (take 30) . recentFirst
                    getResourceBody
                        >>= applyAsTemplate indexCtx
                        >>= loadAndApplyTemplate "templates/default.html" postCtx
                        >>= relativizeUrls
            
            -- Parse html files
            match "contact.html" $ do
                route idRoute
                compile $ do
                    let indexCtx = field "posts" $ \_ -> (postList "posts/*") $ fmap (take 30) . recentFirst
                    getResourceBody
                        >>= applyAsTemplate indexCtx
                        >>= loadAndApplyTemplate "templates/default.html" postCtx
                        >>= relativizeUrls
            
            -- Parse html files
            match "writings.html" $ do
                route idRoute
                compile $ do
                    let indexCtx = field "posts" $ \_ -> (postList "posts/*") $ fmap (take 30) . recentFirst
                    getResourceBody
                        >>= applyAsTemplate indexCtx
                        >>= loadAndApplyTemplate "templates/default.html" postCtx
                        >>= relativizeUrls
            
            -- Parse html files
            match "writings-fr.html" $ do
                route idRoute
                compile $ do
                    let indexCtx = field "posts" $ \_ -> (postList "posts-fr/*") $ fmap (take 30) . recentFirst
                    getResourceBody
                        >>= applyAsTemplate indexCtx
                        >>= loadAndApplyTemplate "templates/default.html" postCtx
                        >>= relativizeUrls
            
            -- Parse html files
            match "writings-jp.html" $ do
                route idRoute
                compile $ do
                    let indexCtx = field "posts" $ \_ -> (postList "posts-jp/*") $ fmap (take 30) . recentFirst
                    getResourceBody
                        >>= applyAsTemplate indexCtx
                        >>= loadAndApplyTemplate "templates/default.html" postCtx
                        >>= relativizeUrls
        
            -- Compile templates
            match "templates/*" $ compile templateCompiler
        
            -- Compile templates
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

-- Build the list of posts
postList :: Pattern -> ([Item String] -> Compiler [Item String]) -> Compiler String
postList dir sortFilter =
    do
        posts   <- sortFilter =<< loadAll dir
        itemTpl <- loadBody "templates/post-item.html"
        list    <- applyTemplateList itemTpl postCtx posts
        return list

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

