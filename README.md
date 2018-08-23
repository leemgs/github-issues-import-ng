
## Introduction ##
The **github-issue-import-ng** repository is to import issues and pull requests from one repository to another; works even for private repositories, and if the two repositories are not related to each other in any way.

It is forked as a next generation github issue importer from the below websites to transfer issues and pull requests between github and github (or github enterprise) repository.
* Original website - [`mokorenkov/tools`](https://github.com/mkorenkov/tools).
* Forked website - [`IQAndreas/github-issues-import`](https://github.com/IQAndreas/github-issues-import).

The goal of this repository is as following:
* Support a stability by fixing bugs that people report
* Keep a maintenance to review and merge pull requests
* Add a new features that are proposed via a pull request process by contributors
* Support a issue migration between github enterprise and github community as well as github communities


## Getting Started ##
To quickly get started, rename `config.ini.sample` to `config.ini`, and edit the fields to match your login info and repository info. If you want to store `config.ini` file in a different folder, use the `--config <file>` option to specify which config file to load in.
```bash
$ cp ./config.ini.sample ./config.ini
$ vi ./config.ini
$ vi ./run-all-issue.sh
$ ./run-all-issue.sh
```


## Advanced ##

Run the script with the following command to import all open issues into the repository defined in the config:

```bash
 $ python3 gh-issues-import-ng.py --open
```

If you want to import all issues including the closed ones, use `--all` instead of `--open`. Closed issues will be automatically closed in the target repository, but titles will begin with `[ISSUE][CLOSED]` and `[PR][CLOSE]`.

Or to only import specific issues, run the script and include the issue numbers of all issues you wish to import.

```
 $ python3 gh-issues-import.py --issues 25 26 29
```

Every issue imported will create a new issue in the target repository. Remember that the ID of the issue in the new repository will most likely not be the same as the ID of the original issue. 

If the issue is a pull request, this will be indicated on the issue, and a link to the code will be provided. However, it will be treated as a new issue in the target repository, and **not** a pull request. Pulling in the suggested code into the repository will need to be done manually.

Any comments on the issue will be imported, however, the author of all imported comments will be the account specified in the `config.ini` file. Instead, a link and header is provided for each comment indicating who the original author was and the original date and time of the comment. Any subsequent comments added to the issue after it has been imported into the target repository will not be included.

Labels and milestones attached to the issue will be imported and added to the target repository if they do not already exist there. If the label or milestone with the same name already exists, the issue will point to the existing one, and any difference in the description or other details will be ignored.

If allowed by GitHub's policies, it may be a good idea to use a token key instead of a password of a "neutral" account to import the issues and issue comments.
* https://developer.github.com/apps/building-github-apps/understanding-rate-limits-for-github-apps/
* https://developer.github.com/v3/rate_limit/

## Evaluation ##
<img src=./screenshot01.png>

* [**Example issue (with label)**](https://github.com/IQAndreas-testprojects/github-issues-import-example/issues/8) ([original](https://github.com/IQAndreas/github-issues-import/issues/1))
* [**Example pull request**](https://github.com/IQAndreas-testprojects/github-issues-import-example/issues/9) ([original](https://github.com/IQAndreas/github-issues-import/issues/2))
* [**Example issue with comments**](https://github.com/IQAndreas-testprojects/github-issues-import-example/issues/10) ([original](https://github.com/IQAndreas/github-issues-import/issues/3))
* [**Example issue with milestone**](https://github.com/IQAndreas-testprojects/github-issues-import-example/issues/11) ([original](https://github.com/IQAndreas/github-issues-import/issues/9))

