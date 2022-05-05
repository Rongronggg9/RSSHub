# RSSHub Dockerfile for [Railway.app]

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/new/template/PyitVR) <- To be replaced by the maintainer.

## Upstream usage

1. Use the above button to deploy RSSHub to [Railway]
2. [Railway] will create a new repository for you and the default branch is named `main` (**WARNING**: This is not a fork, you will only get an orphan `main` branch copied from the upstream `railway` branch)
3. Turn to the newly created repository
4. Rename the default branch (`main`) to `railway`
5. (In case not enabled by default) turn to repository settings, then switch to the `Actions` - `General` tab, select `Allow all actions and reusable workflows` then `Save` your changes

### What if I already have a fork?

Never mind, [Railway] will prompt you to rename the new repository.

If you insist on using your fork, follow the below section. In particular, skipping step-5/6, and replacing `railway-downstream` with `railway` in the last two steps.

## Downstream usage

> Assuming that you have already had a fork with some modifications, and you want to apply these modifications to the deployment on [Railway].

1. Use the above button to deploy RSSHub to [Railway]
2. Delete the newly created repository created by [Railway]
3. Turn to your fork
4. Make sure the `master` branch of your fork is up-to-date with `.github/workflows/railway-update.yml` existing.
5. Turn on GitHub Actions for your fork (refer to the last step of the previous section)
6. Publish your own image to Docker Hub by filling in repository secrets (`DOCKER_USERNAME` and `DOCKER_PASSWORD`)
7. Turn to the `Actions` page of your fork, switch to the `[docker] CI for releases` workflow, then `Run workflow`
8. Wait for the workflow to finish, then run the `Update Dockerfile for Railway.app` workflow in the same way
9. Wait for the workflow to finish, then check if the `railway-downstream` branch has been created
10. Turn to [Railway Dashboard](https://railway.app/dashboard) then open your project, switch to the `Settings` tab and make the `Deployment Trigger` track the `railway-downstream` branch

## Limitations

### Update frequency

Your deployment can only be updated **up to once a day** (UTC). Automated updates are performed at 12:00 (UTC) every day. You may trigger an update by manually running the workflow.

### Pricing

Every single user without a verified payment method has a $5 free credit granted monthly. After verification, the free credit increases to $10. $5 should be enough if you merely deploy RSSHub on [Railway].

Without a verified payment method, your deployment will be paused until the next month if exceeding the free credit ($5).

With a verified payment method, you will get charged if exceeding the free credit ($10).

### Payment method

* Only debit or credit card is supported.
* UnionPay is not supported.
* If you use a debit card, make sure to have a balance of at least $10 to pass the verification (just for verification, your balance will not be charged).

### USE AT YOUR OWN RISK

According to the [fair-use policy](https://railway.app/legal/fair-use), RSSHub does have a prohibited dependency. RSSHub is not responsible for any damage caused by the use of RSSHub on [Railway].

It is even impossible to tell what the dependency is even in README, otherwise [Railway] would reject the deployment.

[Railway.app]: https://railway.app
[Railway]: https://railway.app
