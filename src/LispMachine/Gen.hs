{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE TupleSections              #-}

module LispMachine.Gen where

import Control.Monad.RWS hiding (ap)
import Data.Text.Lazy (Text)
import qualified Data.Text.Lazy as T

import LispMachine.Instructions
import LispMachine.Flatten
import LispMachine.Print

data GenState = GenState
    { lastLabelId :: Int
    } deriving (Show, Eq, Ord)

data RRef = RRef Text Int deriving (Show, Eq, Ord)

toLabel :: RRef -> Label
toLabel (RRef name i) = "lbl_" ++ T.unpack name ++ "_" ++ show i

toRefLabel :: RRef -> Ref
toRefLabel = Ref . toLabel

newtype CondBlock = CondBlock { getCondBlock :: [Statement] }
                  deriving (Show, Eq, Ord, Monoid)

type GenM env = RWST env ([Statement], [CondBlock]) GenState (Either String)

putI :: Instruction Ref -> GenM e ()
putI = tell . (, mempty) . (:[]) . Instr

putLabel :: RRef -> GenM e ()
putLabel = tell . (, mempty) . (:[]) . SetLabel . toLabel

ldc :: Int -> GenM e ()
ldc x = putI $ LDC x

ld :: Int -> Int -> GenM e ()
ld n i = putI $ LD n i

st :: Int -> Int -> GenM e ()
st n i = putI $ ST n i

add :: GenM e ()
add = putI ADD

sub :: GenM e ()
sub = putI SUB

mul :: GenM e ()
mul = putI MUL

div :: GenM e ()
div = putI DIV

ceq  :: GenM e ()
ceq = putI CEQ

cgt  :: GenM e ()
cgt = putI CGT

cgte :: GenM e ()
cgte = putI CGTE

atom :: GenM e ()
atom = putI ATOM

cons :: GenM e ()
cons = putI CONS

car  :: GenM e ()
car = putI CAR

cdr  :: GenM e ()
cdr = putI CDR

sel  :: RRef -> RRef -> GenM e ()
sel t f = putI $ SEL (toRefLabel t) (toRefLabel f)

join :: GenM e ()
join = putI JOIN

ldf  :: RRef -> GenM e ()
ldf f = putI $ LDF (toRefLabel f)

ap :: Int -> GenM e ()
ap n = putI $ AP n

rtn  :: GenM e ()
rtn = putI RTN

dum  :: Int -> GenM e ()
dum n = putI $ DUM n

rap  :: Int -> GenM e ()
rap n = putI $ RAP n

stop :: GenM e ()
stop = putI STOP

tsel :: RRef -> RRef -> GenM e ()
tsel t f = putI $ TSEL (toRefLabel t) (toRefLabel f)

tap  :: Int -> GenM e ()
tap n = putI $ TAP n

trap :: Int -> GenM e ()
trap n = putI $ TRAP n

dbug :: GenM e ()
dbug = putI DBUG

brk  :: GenM e ()
brk = putI BRK

mkLabel :: GenM e RRef
mkLabel = mkNamedLabel T.empty

mkNamedLabel :: Text -> GenM e RRef
mkNamedLabel name = do
  lastId <- gets lastLabelId
  modify (\s -> s {lastLabelId = succ lastId})
  return $ RRef name $ succ lastId

block :: RRef -> GenM e a -> GenM e a
block ref gen = do
  putLabel ref
  gen

condBlock :: RRef -> GenM e a -> GenM e a
condBlock ref gen =
  censor toCondBlock $ do
    putLabel ref
    gen
  where
    toCondBlock :: ([Statement], [CondBlock]) -> ([Statement], [CondBlock])
    toCondBlock res@([], _) = res
    toCondBlock (xs, ys)
      | last xs /= Instr JOIN =
        error $ "conditional block does not end in JOIN:\n" ++ show xs
      | otherwise             =
        (mempty, ys ++ [CondBlock xs])

initEnv :: ()
initEnv = ()

initState :: GenState
initState = GenState { lastLabelId = 0 }

genProgram :: e -> GenM e () -> Either String Program
genProgram initEnv gen = fmap (Program . f) $ runRWST gen initEnv initState
    where
      f (_, _, (stms, condBlocks)) = stms ++ concatMap getCondBlock condBlocks

genToString :: e -> GenM e () -> String
genToString initEnv = either error showProgram . (flatten <=< genProgram initEnv)
