# binder + flowR

This repository demonstrates how a project from OSF can be containerized and tested using Binder. We facilitate a one-click launch of the OSF project, allowing anyone to browse, execute the code, and verify or compare the results from the associated research paper. This aligns with the objectives of the **CodeInspector project**, where we aim to enable **browser-based reproducibility and evaluation of open science projects**.

## How It Works

### 1. Downloading the OSF Project
We use the **OSF API** to retrieve a project hosted on OSF. This is done using the Python package `osfclient`.

For demonstration purposes, we use the following OSF-hosted project:

> **Carnevali, L., Valori, I., Altoè, G., & Farroni, T. (2024, January 23).**
> _Interpersonal motor synchrony in Autism: systematic review and meta-analysis._ Retrieved from [osf.io/dqjyh](https://osf.io/dqjyh)  
> **License:** CC-By Attribution 4.0 International

This project is downloaded to a folder named after its **OSF project ID**, which in this case is `dqjyh`.

---

### 2. Extracting Dependencies Using flowR
We utilize **[flowR](https://github.com/flowr-analysis/flowr)** to extract dependencies from the **R files** contained in the OSF project.

#### What is flowR?
**flowR** is a sophisticated **static dataflow analyzer** for the R programming language. One of its core features is **dependency analysis**:
- Identifies the **libraries** required by the project
- Detects **data files** that are read by the scripts
- Recognizes **R scripts** that are sourced
- Lists the **output files** generated

These dependencies are crucial for ensuring reproducibility, and they are used to generate **install.R** file, which is necessary for installing dependencies in RStudio.

### 3. Setting Up Binder

To make flowR available inside the Binder environment, we integrate it using two key components:

#### postBuild

The postBuild script ensures that flowR is installed when launching the RStudio session:
```bash
#!/bin/bash
# Install remotes package in R
R -e "install.packages('remotes')"

# Install FlowR from GitHub using remotes
R -e "remotes::install_github('flowr-analysis/rstudio-addin-flowr')"
```

#### .Rprofile

To automatically set up the flowR RStudio add-in, we include the following in .Rprofile:
```r
rstudioaddinflowr:::install_node_addin()
```
### 4. Creating a Docker Image for Reproducibility
The project is containerized using [My Binder](https://mybinder.org) to enable execution directly from a web browser. This allows researchers to:
- Browse the OSF project’s code
- Execute the analysis
- Compare results with the original paper

#### Alternative: Using repo2docker
Instead of using MyBinder, you can manually build the Docker image using `repo2docker`:

#### Steps to Build and Run the Image
1. Install `repo2docker` by following the guide [here](https://repo2docker.readthedocs.io/en/latest/install.html).
2. Clone this repository:
   ```bash
   git clone https://github.com/Code-Inspect/binder-flowR.git
   ```
3. Build and launch the container using:
   ```bash
   jupyter-repo2docker https://github.com/Code-Inspect/binder-flowR
   ```

## One-Click Reproducibility
By leveraging Binder, we facilitate a **one-click launch** of the OSF project, making it accessible for anyone to explore, execute, and verify the analysis. This contributes to the broader goals of **browser-based reproducibility** and **evaluation of open science projects**, as pursued under the **CodeInspector project.**

🚀 **Click below to launch the project on MyBinder:**  
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/Code-Inspect/binder-flowR/HEAD?urlpath=rstudio)

🚀 **Click below to launch the project on the NFDI JupyterHub:**  
[![NFDI](https://nfdi-jupyter.de/images/nfdi_badge.svg)](https://hub.nfdi-jupyter.de/r2d/gh/Code-Inspect/binder-flowR/HEAD?urlpath=rstudio)

---

By integrating **OSF**, **flowR**, and **Binder**, we aim to enhance transparency and reproducibility in computational social science and beyond. This repository serves as an example of how research projects can be packaged and shared in a fully executable, browser-based environment. 


---

This work was funded by the German Research Foundation (DFG) under project No. 504226141.
