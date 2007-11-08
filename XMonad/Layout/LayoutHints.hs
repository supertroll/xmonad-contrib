{-# LANGUAGE FlexibleInstances, MultiParamTypeClasses, TypeSynonymInstances #-}

-----------------------------------------------------------------------------
-- |
-- Module       : XMonad.Layout.LayoutHints
-- Copyright    : (c) David Roundy <droundy@darcs.net>
-- License      : BSD
--
-- Maintainer   : David Roundy <droundy@darcs.net>
-- Stability    : unstable
-- Portability  : portable
--
-- Make layouts respect size hints.
-----------------------------------------------------------------------------

module XMonad.Layout.LayoutHints (
    -- * usage
    -- $usage
    layoutHints,
    LayoutHints) where

import XMonad.Operations ( applySizeHints, D )
import Graphics.X11.Xlib
import Graphics.X11.Xlib.Extras ( getWMNormalHints )
import XMonad hiding ( trace )
import XMonad.Layout.LayoutModifier
import Control.Monad.Reader ( asks )

-- $usage
-- > import XMonad.Layout.LayoutHints
-- > layouts = [ layoutHints tiled , layoutHints $ Mirror tiled ]

-- %import XMonad.Layout.LayoutHints
-- %layout , layoutHints $ tiled
-- %layout , layoutHints $ Mirror tiled

layoutHints :: (LayoutClass l a) => l a -> ModifiedLayout LayoutHints l a
layoutHints = ModifiedLayout LayoutHints

-- | Expand a size by the given multiple of the border width.  The
-- multiple is most commonly 1 or -1.
adjBorders                :: Dimension -> Dimension -> D -> D
adjBorders bW mult (w,h)  = (w+2*mult*bW, h+2*mult*bW)

data LayoutHints a = LayoutHints deriving (Read, Show)

instance LayoutModifier LayoutHints Window where
    modifierDescription _ = "Hinted"
    redoLayout _ _ _ xs = do
                            bW <- asks (borderWidth . config)
                            xs' <- mapM (applyHint bW) xs
                            return (xs', Nothing)
     where
        applyHint bW (w,Rectangle a b c d) =
            withDisplay $ \disp -> do
                sh <- io $ getWMNormalHints disp w
                let (c',d') = adjBorders 1 bW . applySizeHints sh . adjBorders bW (-1) $ (c,d)
                return (w, Rectangle a b c' d')