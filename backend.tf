terraform {
  cloud {

    organization = "EdisonLim_PersonalOrg"

    workspaces {
      name = "PersonalWebsiteBackendGitHubActions"
    }
  }
}