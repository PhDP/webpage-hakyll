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

