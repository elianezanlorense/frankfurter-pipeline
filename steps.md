gh auth login
gh secret set SSH_PUBLIC_KEY < ~/.ssh/zoocamp_rsa.pub
gh secret set SSH_PRIVATE_KEY < ~/.ssh/zoocamp_rsa  

project_id 
gcloud projects list

gcloud iam workload-identity-pools list \
  --project=zoocamp-450e \
  --location=global


gcloud iam workload-identity-pools providers list \
  --project=zoocamp-450e  \
  --location=global \
  --workload-identity-pool=projects/633690587904/locations/global/workloadIdentityPools/zoocamp-450e-github-pool-2

gh secret set GCP_WIF_PROVIDER \
  --body "$(gcloud iam workload-identity-pools providers describe meu-provider \
    --project=zoocamp-450e  \
    --location=global \
    --workload-identity-pool=projects/633690587904/locations/global/workloadIdentityPools/zoocamp-450e-github-pool-2 \
    --format='value(rojects/633690587904/locations/global/workloadIdentityPools/zoocamp-450e-github-pool-2/providers/zoocamp-450e-gh)')"

  gh secret set GCP_WIF_PROVIDER \
  --body "projects/633690587904/locations/global/workloadIdentityPools/zoocamp-450e-github-pool-2/providers/zoocamp-450e-gh"

  grep -r "zoocamp-project-tf-state\|zoocamp-450e-tf-state" ./terraform/