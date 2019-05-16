{-# LANGUAGE DeriveAnyClass         #-}
{-# LANGUAGE DeriveGeneric          #-}
{-# LANGUAGE FlexibleContexts       #-}
{-# LANGUAGE FlexibleInstances      #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses  #-}
{-# LANGUAGE OverloadedStrings      #-}
{-# LANGUAGE Rank2Types             #-}
{-# LANGUAGE ScopedTypeVariables    #-}
{-# LANGUAGE StandaloneDeriving     #-}
{-# LANGUAGE TemplateHaskell        #-}
{-# LANGUAGE TypeFamilies           #-}
{-# LANGUAGE TypeOperators          #-}

module Scarf.Types where

import           Scarf.Common
import           Scarf.PackageSpec

import           Data.Aeson
import           Data.Aeson.TH
import           Data.Maybe
import           Data.Pool
import           Data.SemVer
import           Data.Text                  (Text)
import           Data.Text.Encoding
import           Data.Time.Clock
import           Distribution.License
import qualified Distribution.Types.Version
import           GHC.Generics
import           Lens.Micro.Platform
import           Network.HTTP.Client        (Manager, defaultManagerSettings,
                                             newManager)
import           Prelude                    hiding (FilePath, writeFile)
import           Servant.Auth.Server
import           System.Exit



data Config = Config
  { homeDirectory  :: FilePath
  , userApiToken   :: Maybe Text
  , httpManager    :: Manager
  , backendBaseUrl :: String
  }

data ExecutionResult = ExecutionResult
  { result    :: ExitCode
  , runtimeMS :: Integer
  , args      :: [Text]
  } deriving (Show)

data CreateUserRequest = CreateUserRequest
  { createUserRequestEmail    :: Text
  , createUserRequestUsername :: Text
  , createUserRequestPassword :: Text
  }

deriveJSON
  defaultOptions
  {fieldLabelModifier = makeFieldLabelModfier "CreateUserRequest"}
  ''CreateUserRequest
makeFields ''CreateUserRequest

data LoginRequest = LoginRequest
  { loginRequestEmail    :: Text
  , loginRequestPassword :: Text
  }

deriveJSON
  defaultOptions {fieldLabelModifier = makeFieldLabelModfier "loginRequest"}
  ''LoginRequest
makeFields ''LoginRequest

data Session = Session {
  sessionUserId   :: Integer,
  sessionEmail    :: Text,
  sessionUsername :: Text
  } deriving (Generic, Show)

deriveJSON
  defaultOptions {fieldLabelModifier = makeFieldLabelModfier "session"}
  ''Session
deriving instance ToJWT Session
deriving instance FromJWT Session
makeFields ''Session

data CreatePackageCallRequest = CreatePackageCallRequest
  { createPackageCallRequestReleaseUuid :: Text
  , createPackageCallRequestExit        :: Integer
  , createPackageCallRequestRunTimeMs   :: Integer
  , createPackageCallRequestArgString   :: Text
  }

deriveJSON
  defaultOptions
  {fieldLabelModifier = makeFieldLabelModfier "CreatePackageCallRequest"}
  ''CreatePackageCallRequest
makeFields ''CreatePackageCallRequest

data  CreatePackageRequest = CreatePackageRequest {
  createPackageRequestName             :: Text,
  createPackageRequestShortDescription :: Text,
  createPackageRequestLongDescription  :: Maybe Text
                                                  }
deriveJSON
  defaultOptions
  {fieldLabelModifier = makeFieldLabelModfier "CreatePackageRequest"}
  ''CreatePackageRequest
makeFields ''CreatePackageRequest

data GetUserAccountDetailsResponse = GetUserAccountDetailsResponse
  { getUserAccountDetailsResponseApiToken :: Text
  }

deriveJSON
  defaultOptions
  {fieldLabelModifier = makeFieldLabelModfier "GetUserAccountDetailsResponse"}
  ''GetUserAccountDetailsResponse
makeFields ''GetUserAccountDetailsResponse

data UpdatePasswordRequest = UpdatePasswordRequest
  { updatePasswordRequestCurrentPassword :: Text
  , updatePasswordRequestNewPassword     :: Text
  }

deriveJSON
  defaultOptions
  {fieldLabelModifier = makeFieldLabelModfier "UpdatePasswordRequest"}
  ''UpdatePasswordRequest
makeFields ''UpdatePasswordRequest

data PackageStat = PackageStat
  { packageStatPackage       :: Text
  , packageStatVersion       :: Text
  , packageStatPlatform      :: Scarf.PackageSpec.Platform
  , packageStatExit          :: Integer
  , packageStatCount         :: Integer
  , packageStatAverageTimeMs :: Double
  }

deriveJSON
  defaultOptions
  {fieldLabelModifier = makeFieldLabelModfier "PackageStat"}
  ''PackageStat
makeFields ''PackageStat


data PackageStatsResponse = PackageStatsResponse
  { packageStatsResponseStats :: [PackageStat]
  }

deriveJSON
  defaultOptions
  {fieldLabelModifier = makeFieldLabelModfier "PackageStatsResponse"}
  ''PackageStatsResponse
makeFields ''PackageStatsResponse

data PackageSummary = PackageSummary {
  packageSummaryUuid           :: Text,
  packageSummaryName           :: Text,
  packageSummaryOwner          :: Text,
  packageSummaryLicense        :: License,
  packageSummaryLatestReleases :: [(Scarf.PackageSpec.Platform, Version)]
}

data Package = Package {
  packageUuid               :: Text
  , packageOwner            :: Text
  , packageName             :: Text
  , packageShortDescription :: Text
  , packageLongDescription  :: Maybe Text
  , packageCreatedAt        :: UTCTime
                       } deriving (Show)

deriveJSON
  defaultOptions
  {fieldLabelModifier = makeFieldLabelModfier "Package"}
  ''Package
makeFields ''Package

data PackageRelease = PackageRelease {
    packageReleaseUuid                    :: Text
  , packageReleaseUploaderName            :: Text
  , packageReleaseAuthor                  :: Text
  , packageReleaseCopyright               :: Text
  , packageReleaseLicense                 :: License
  , packageReleaseVersion                 :: Text
  , packageReleasePlatform                :: Scarf.PackageSpec.Platform
  , packageReleaseExecutableUrl           :: Text
  , packageReleaseExecutableSignature     :: Maybe Text
  , packageReleaseSimpleExecutableInstall :: Maybe Text
  , packageReleaseIncludes                :: [Text]
  , packageReleaseCreatedAt               :: UTCTime
                                     } deriving (Show)

deriveJSON
  defaultOptions
  {fieldLabelModifier = makeFieldLabelModfier "PackageRelease"}
  ''PackageRelease
makeFields ''PackageRelease

data PackageDetails = PackageDetails
  { packageDetailsPackage       :: Package
  , packageDetailsOwnerName     :: Text
  , packageDetailsReleases      :: [PackageRelease]
  , packageDetailsLicense       :: Maybe License
  , packageDetailsTotalInstalls :: Integer
  } deriving (Show)

deriveJSON
  defaultOptions
  {fieldLabelModifier = makeFieldLabelModfier "PackageDetails"}
  ''PackageDetails
makeFields ''PackageDetails

deriveJSON
  defaultOptions
  {fieldLabelModifier = makeFieldLabelModfier "PackageSummary"}
  ''PackageSummary
makeFields ''PackageSummary

data PackageSearchResults = PackageSearchResults {
  packageSearchResultsQuery   :: Text,
  packageSearchResultsResults :: [PackageDetails]
}

deriveJSON
  defaultOptions
  {fieldLabelModifier = makeFieldLabelModfier "PackageSearchResults"}
  ''PackageSearchResults
makeFields ''PackageSearchResults

data ValidatedPackageSpec = ValidatedPackageSpec {
  validatedPackageSpecName          :: Text,
  validatedPackageSpecVersion       :: Text,
  validatedPackageSpecAuthor        :: Text,
  validatedPackageSpecCopyright     :: Text,
  validatedPackageSpecLicense       :: License,
  validatedPackageSpecDistributions :: [Scarf.PackageSpec.PackageDistribution]
} deriving (Show, Generic)

instance ToJSON Distribution.Types.Version.Version
instance FromJSON Distribution.Types.Version.Version
instance ToJSON License
instance FromJSON License

deriveJSON
  defaultOptions
  {fieldLabelModifier = makeFieldLabelModfier "ValidatedPackageSpec"}
  ''ValidatedPackageSpec
makeFields ''ValidatedPackageSpec

data PackageCall = PackageCall {
  packageCallExit      :: Integer,
  packageCallTimeMs    :: Integer,
  packageCallArgsList  :: [Text],
  packageCallCreatedAt :: UTCTime
}

deriveJSON
  defaultOptions
  {fieldLabelModifier = makeFieldLabelModfier "PackageCall"}
  ''PackageCall
makeFields ''PackageCall

data PackageCallsResponse = PackageCallsResponse {
  packageCallsResponseCalls :: [PackageCall]
                                                 }

deriveJSON
  defaultOptions
  {fieldLabelModifier = makeFieldLabelModfier "PackageCallsResponse"}
  ''PackageCallsResponse
makeFields ''PackageCallsResponse

data UserInstallation = UserInstallation
  { userInstallationName    :: Text
  , userInstallationUuid    :: Text
  , userInstallationVersion :: Text
  } deriving (Show)

deriveJSON
  defaultOptions
  {fieldLabelModifier = makeFieldLabelModfier "UserInstallation"}
  ''UserInstallation
makeFields ''UserInstallation

data UserState = UserState
  { userStateDepends :: Maybe [UserInstallation]
  } deriving (Show)

deriveJSON
  defaultOptions
  {fieldLabelModifier = makeFieldLabelModfier "UserState"}
  ''UserState
makeFields ''UserState
