---
output: html_document
---

# phyExp
*phyExp* is an *R* package that performs expression phylogenetic analysis
from *RNA-seq* count data, including optimized input formatting, normalization
and pair-wise distance evaluation, preliminary phylogenetic network analysis.

*phyExp* package is under active developing, version 0.1 is availiable at <https://github.com/hr1912/phyExp>.

A convenient way to install package from github is through *devtools* package:

```{r, eval=FALSE}
install.packages(devtools)
devtools::install_github("hr1912/phyExp")
```

Load the package in the usual way:

```{r}
library(phyExp)
```

The construction function `TEconstruct` loads in the reads count data file as well as a gene infomation file (gene lengths and ortholog), and wraps them in a list of *taxonExp* objects (one *taxaExp* object).

In the package, we include files tranformed from six tissues' expression reads count data of nine tetrapod species.
If you want to transform your own data, a tranformation Perl script to format raw outputs of *TopHat2* to "*phyExp* compatible" is availiable at <https://github.com/hr1912/phyExp/blob/master/tools/format2phyexp.pl>

```{r, eval=FALSE}
taxa.objects = TEconstruct(readsCountFP = system.file('extdata/tetraexp.reads.count.raw.txt', package='phyExp'),
  geneInfoFP = system.file('extdata/tetraexp.gene.length.ortholog.txt', package='phyExp'), 
  taxa = "all", subtaxa = c("Brain", "Cerebellum"), calRPKM=TRUE, rmOut=TRUE)
```

The construction process takes **several minutes** on a desktop computer depanding on data size and hardware performance. Specify **"taxa"** and **"subtaxa"** options in the function when using partial of your data. The construction process will be faster.
If you are hesitated to test the package, the construnction process is already done by us and you can load the objects like:

```{r}
data(tetraexp)
```

You can take a look at what the loaded objects:
```{r}
print(tetraexp.objects, details = TRUE)
```

```{r}
print(tetraexp.objects[[1]], printlen = 6)
head(tetraexp.objects[[1]]$rpkm.rmOut)
```

Let us quickly jump to the issue of creating phylogeny from *taxaExp* object. 
First, we generate a distance matrix:

```{r, message=FALSE}
dismat <- expdist(tetraexp.objects, taxa = "all",
                 subtaxa = "Brain",
                 method = "rho")
dismat
```

You can specify **"taxa"** and **"subtaxa"** options in the `expdist` function as well. The default model **"rho"** is to calculate pair-wise distances by "1-rho", which "rho" refers to Spearman’s coefficient of expression level. 

After distance matrix is created, you can construct phylogeny by Neighbor-Joining, and you can also generate bootstrap values by `boot.exphy` function:

```{r}
library(ape)
tr <- nj(dismat)
tr <- root(tr, "Chicken_Brain")
bs <- boot.exphy(tr, tetraexp.objects, method = "rho",
                 B = 100, rooted = "Chicken_Brain")
tr$node.label = bs
plot(tr, show.node.label = TRUE)
```