{-# LANGUAGE FlexibleInstances #-}
module ScriptBuiltins where

import ExecScript
import Data.List (intercalate)
stdEnv :: Namespace
stdEnv = Namespace [
    ("print", adaptToVal sPrint),
    ("+", adaptToVal sAdd),
    ("-", adaptToVal sSubtract),
    ("/", adaptToVal sDivide),
    ("*", adaptToVal sMultiply),
    ("plus", adaptToVal sAdd),
    ("minus", adaptToVal sSubtract),
    ("div", adaptToVal sDivide),
    ("mul", adaptToVal sMultiply),
    ("!!", adaptToVal sIndex),
    ("index", adaptToVal sIndex),
    ("cons", adaptToVal sCons),
    (":", adaptToVal sUpdateName),
    ("head", adaptToVal sHead),
    ("tail", adaptToVal sTail),
    ("init", adaptToVal sInit),
    ("last", adaptToVal sLast),
    ("set", adaptToVal sSet),
    ("insert", adaptToVal sInsert),
    ("null", Void),
    ("bool", adaptToVal sBool),
    ("eq", adaptToVal sEquals),
    ("?=", adaptToVal sEquals),
    ("cmp", adaptToVal sCompare),
    ("<", adaptToVal sLessThan),
    (">", adaptToVal sGreaterThan),
    ("<=", adaptToVal sLessThanEquals),
    (">=", adaptToVal sGreaterThanEquals),
    ("readFile", adaptToVal sReadFile),
    ("writeFile", adaptToVal sWriteFile),
    ("join", adaptToVal sJoin),
    ("map", adaptToVal sMap),
    ("reduce", adaptToVal sReduce),
    ("appendFile", adaptToVal sAppendFile),
    ("merge", adaptToVal sMerge),
    ("nameExists", adaptToVal sNameExists),
    ("safeGet", adaptToVal sSafeGet),
    ("!=", adaptToVal sNotEquals),
    ("&&", adaptToVal sAnd),
    ("||", adaptToVal sOr),
    ("not", adaptToVal sNot),
    ("and", adaptToVal sAnd),
    ("or", adaptToVal sOr),
    ("input", adaptToVal sInput),
    ("toString", adaptToVal sToString),
    ("vars", adaptToVal sVars)]




sVars :: SFunction
sVars globals [] = return $ StringV $ show globals
sVars globals [a] = return $ StringV $ show (getVars a)

sToString :: SFunction
sToString globals [StringV str] = return (StringV str)
sToString globals [ObjectV a] = callMethod' globals (ObjectV a) "toString" []
sToString globals [a] = return $ StringV $ show a

sPrint :: SFunction
sPrint globals [StringV str] = putStrLn str >> return Void
sPrint globals [ErrorV a] = return (ErrorV a)
sPrint globals [ObjectV a] = (callMethod' globals (ObjectV a) "toString" []) >>= (\(StringV str) -> putStrLn str >> return Void)
sPrint globals [a] = print a >> return Void
sPrint globals a = return (ErrorV (show a))

callMethod' :: Namespace -> Value -> String -> [IO Value] -> IO Value
callMethod' globals obj name args = callMethod globals obj (getAttr name obj) args

sInput :: SFunction
sInput globals [] = fmap StringV getLine



sSubtract :: SFunction
sSubtract globals [NumberV a, NumberV b] = return $ NumberV (a - b)

sAdd :: SFunction
sAdd globals [NumberV a, NumberV b] = return $ NumberV (a + b)
sAdd globals [StringV a, b] = return $ StringV (a ++ (toString b))
sAdd globals [ListV a, ListV b] = return $ ListV (a ++ b)

sMultiply :: SFunction
sMultiply globals [NumberV a, NumberV b] = return $ NumberV (a * b)
sMultiply globals [StringV a, NumberV b] = return $ StringV (concat $ replicate b a)
sMultiply globals [ListV a, NumberV b] = return $ ListV (concat $ replicate b a)

sDivide :: SFunction
sDivide globals [NumberV a, NumberV b] = return $ NumberV $ (div a b)


sIndex :: SFunction
sIndex globals [ListV a, NumberV b] = return (a !! b)
sIndex globals [StringV a, NumberV b] = return $ StringV ([a !! b])

sCons :: SFunction
sCons globals [a, ListV b] = return (ListV (a:b))

sHead :: SFunction
sHead globals [ListV a] = return $ head a

sTail :: SFunction
sTail globals [ListV a] = return $ ListV $ tail a

sInit :: SFunction
sInit globals [ListV a] = return $ ListV $ init a

sLast :: SFunction
sLast globals [ListV a] = return $ last a

set :: [a] -> Int -> a -> [a]
set xs i val = (take i xs) ++ (val:(drop (succ i) xs))

insert :: [a] -> Int -> a -> [a]
insert xs i val = (take i xs) ++ [val] ++ (drop i xs)

sSet :: SFunction
sSet globals [ListV xs, NumberV i, val] = return $ ListV $ set xs i val

sInsert :: SFunction
sInsert globals [ListV xs, NumberV i, val] = return $ ListV $ insert xs i val

sBool :: SFunction
sBool globals [a] = return $ NumberV $ if isTrue a then 1 else 0


sEquals :: SFunction
sEquals globals [a, b] = return $ NumberV $ if (a == b) then 1 else 0

sNotEquals :: SFunction
sNotEquals globals [a, b] = return $ NumberV $ if (a == b) then 0 else 1

sAnd :: SFunction
sAnd globals [a, b] = return $ NumberV $ if (isTrue a && isTrue b) then 1 else 0

sOr :: SFunction
sOr globals [a, b] = return $ NumberV $ if (isTrue a || isTrue b) then 1 else 0

sNot :: SFunction
sNot globals [a] = return $ NumberV $ if (isTrue a) then 0 else 1


instance Ord Value where
    compare (ListV a) (ListV b) = compare a b
    compare (StringV a) (StringV b) = compare a b
    compare (NumberV a) (NumberV b) = compare a b
    compare Void Void = EQ
    compare Void a = LT
    compare a Void = GT

sCompare :: SFunction
sCompare globals [a, b] = return $ NumberV $ case compare a b of
    LT -> -1
    EQ -> 0
    GT -> 1

sLessThan :: SFunction
sLessThan globals [a, b] = return $ NumberV $ case a < b of
    True -> 1
    False -> 0

sGreaterThan :: SFunction
sGreaterThan globals [a, b] = return $ NumberV $ case a > b of
    True -> 1
    False -> 0

sLessThanEquals :: SFunction
sLessThanEquals globals [a, b] = return $ NumberV $ case a <= b of
    True -> 1
    False -> 0

sGreaterThanEquals :: SFunction
sGreaterThanEquals globals [a, b] = return $ NumberV $ case a >= b of
    True -> 1
    False -> 0

sReadFile :: SFunction
sReadFile globals [StringV fname] = fmap StringV (readFile fname)

sWriteFile :: SFunction
sWriteFile globals [StringV fname, StringV text] = (writeFile fname text) >> return Void
sWriteFile globals [StringV fname] = (writeFile fname "") >> return Void

sAppendFile :: SFunction
sAppendFile globals [StringV fname, StringV text] = (appendFile fname text) >> return Void

toString :: Value -> String
toString (StringV a) = a
toString (NumberV a) = show a
toString (ListV a) = show a
toString Void = "null"

sJoin :: SFunction
sJoin globals [ListV a, StringV b] = return $ StringV $ intercalate b (map toString a)
sJoin globals [ListV a] = return $ StringV $ (concat $ map toString a)

sMap :: SFunction
sMap globals [func, ListV xs] = (fmap ListV) $ flipListIO (map thing xs) where
    thing a = callFunction globals func [return a]

sReduce :: SFunction
sReduce globals [func, ListV xs] = foldl1 thing (map return xs) where
    thing a b = callFunction globals func [a, b]

sMerge :: SFunction
sMerge globals [ObjectV (Namespace a), ObjectV (Namespace b)] = return $ ObjectV $ Namespace $ b ++ a

sNameExists :: SFunction
sNameExists globals [thing, StringV str] = return $ NumberV $ case nameExists (getVars thing) str of
    True -> 1
    False -> 0

sSafeGet :: SFunction
sSafeGet globals [thing, StringV str] = return $ case search str (getVars thing) of
    Right val -> val
    Left _ -> Void






