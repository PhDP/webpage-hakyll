--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import Data.Monoid (mappend)
import Hakyll
import GHC.IO.Encoding

--------------------------------------------------------------------------------
main :: IO ()
main = do
    setLocaleEncoding utf8
    setFileSystemEncoding utf8
    setForeignEncoding utf8
    hakyll $ do 
		match "files/*" $ do
			route idRoute
			compile copyFileCompiler

		match "images/*" $ do
			route idRoute
			compile copyFileCompiler
	
		match "css/*" $ do
			route idRoute
			compile compressCssCompiler
	
		match "posts/*.html" $ do
			route idRoute
			compile $ do
				getResourceBody
					>>= loadAndApplyTemplate "templates/post.html" postCtx
                                        >>= saveSnapshot "content"
					>>= loadAndApplyTemplate "templates/default.html" postCtx
					>>= relativizeUrls
	
		match "*.html" $ do
			route idRoute
			compile $ do
				let indexCtx = field "posts" $ \_ -> postList $ fmap (take 30) . recentFirst
				getResourceBody
					>>= applyAsTemplate indexCtx
					>>= loadAndApplyTemplate "templates/default.html" postCtx
					>>= relativizeUrls
	
		match "templates/*" $ compile templateCompiler

                create ["atom.xml"] $ do
                    route idRoute
                    compile $ do
                        let feedCtx = postCtx `mappend` bodyField "description"
                        posts <- fmap (take 10) . recentFirst =<<
                            loadAllSnapshots "posts/*" "content"
                        renderAtom myFeedConfiguration feedCtx posts

--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%Y.%m.%d" `mappend`
    defaultContext

--------------------------------------------------------------------------------
postList :: ([Item String] -> Compiler [Item String]) -> Compiler String
postList sortFilter = do
    posts   <- sortFilter =<< loadAll "posts/*"
    itemTpl <- loadBody "templates/post-item.html"
    list    <- applyTemplateList itemTpl postCtx posts
    return list

myFeedConfiguration :: FeedConfiguration
myFeedConfiguration = FeedConfiguration
    { feedTitle       = "Philippe Desjardins-Proulx"
    , feedDescription = "Artificial Intelligence, Machine Learning, Programming, et al..."
    , feedAuthorName  = "Philippe Desjardins-Proulx"
    , feedAuthorEmail = "phdp@outlook.com"
    , feedRoot        = "http://phdp.github.io/"
    }

