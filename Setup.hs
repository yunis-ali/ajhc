{-# LANGUAGE CPP #-}
import Distribution.Simple
import Distribution.Simple.InstallDirs as I
import Distribution.Simple.LocalBuildInfo as L
import qualified Distribution.Simple.Setup as S
import qualified Distribution.Simple.Program as P
import System.FilePath ((</>), splitDirectories)
import qualified System.FilePath.Posix as Px

make verbosity = P.runProgramInvocation verbosity . P.simpleProgramInvocation "make"

ajhcCmd :: LocalBuildInfo -> FilePath
#ifdef mingw32_HOST_OS
(<//>) = (Px.</>)
ajhcCmd local = Px.joinPath $ splitDirectories $
                 buildDir local <//> "ajhc" <//> "ajhc"
#else
ajhcCmd local = buildDir local </>  "ajhc" </>  "ajhc"
#endif

installStdLib pkg local verbosity copy
    = do let dirs = L.absoluteInstallDirs pkg local copy
             idir = datadir dirs
             bdir = bindir dirs
             icmd = ajhcCmd local
#ifdef mingw32_HOST_OS
             exeExt = ".exe"
#else
             exeExt = ""
#endif
         putStrLn $ "Installing libraries in " ++ idir
         make verbosity
               [ "-f", "Makefile.cabalinst", "install"
               , "TARGET=" ++ idir
               , "AJHC=" ++ icmd
               , "BINDIR=" ++ bdir
               , "EXEEXT=" ++ exeExt
               ]

main :: IO ()
main = defaultMainWithHooks $ simpleUserHooks {
  postInst = \ _ flags pkg lbi -> do
     let verb = (S.fromFlag $ S.installVerbosity flags)
     installStdLib pkg lbi verb NoCopyDest
  }
