
#' @title Bootstrapping expression phylogeny
#'
#' @description  bootstrap by resampling gene (gene, transcript, exon, etc..)
#'
#' @name boot.exphy
#'
#' @param phy an object of class \code{phylo}.
#' @param objects a vector of objects of class \code{taxonExp} or an object of class \code{taxaExp}.
#' @param method  specifying which distance method to be used
#' to estimate expression phylogeny in bootstrapping.
#' @param B the number of bootstrap replicates.
#' @param rooted if "phy" is a rooted tree, a character of the root node's label when constructing "phy";
#' if "phy" is unrooted tree, NULL (NULL by default).
#' @param trees a logical specifying whether to return the bootstrapped trees (FALSE by default).
#'
#' @return similar to boot.phylo in ape, boot.exptree returns a numeric vector
#' which ith element is the number associated to the ith node of phy.
#' if trees = TRUE, boot.exptree returns a list whose first element (named "BP") is like before,
#' and the second element("trees") is a list with the bootstrapped trees.
#'
#' @author Hang Ruan (hang.ruan@hotmail.com).
#'
#' @rdname boot.exphy
#'
#' @export
#'
#' @examples
#'
#' data(tetraexp)
#' dismat <- expdist(tetraexp.objects, taxa = "all",
#'                  subtaxa = "Brain",
#'                  method = "rho")
#' tr <- root(nj(dismat), "Chicken_Brain")
#' plot(tr)
#' bs <- boot.exphy(tr, tetraexp.objects, method = "rho",
#'                  B = 100, rooted = "Chicken_Brain")
#' nodelabels(bs)
#'

boot.exphy = function (phy = NULL, objects = NULL,
                         method = c("rho","brownian", "gu2013", "euc", "cos","jsd"),
                         B = 100, rooted = NULL, trees = FALSE)
{

  method<- match.arg(method)

  message(paste0(date(), ": start bootstapping ", B,  " times using ", method))

  objects_sub_n = length(phy$tip.label)
  object_n = length(objects)

  objects.sub <- vector("list",length = objects_sub_n)

  counter <- 1

  for (i in 1:object_n) {

    if (any(grepl(objects[[i]]$subTaxon.name,phy$tip.label,ignore.case=T))) {
      objects.sub[[counter]] <- objects[[i]]
      counter <- counter + 1
    }

  }

  class(objects.sub) <- "taxaExp"

  if (counter != (objects_sub_n+1)) {
    message(paste0(date(),"incompatible phylo object and taxaExp objects"))
    stop()
  }

  gene_n <- objects.sub[[1]]$gene.num

  message(paste0(date(),": input ", objects_sub_n, " taxa"))
  message(paste0(date(),": total ", gene_n, " genes"))

  reads.count <- matrix(0, nr = gene_n, nc = objects_sub_n)
  gene_length <- matrix(0, nr = gene_n, nc = objects_sub_n)

  meanRPKM <- matrix(0, nr = gene_n, nc = objects_sub_n)

  taxon.names <- vector("character", length = objects_sub_n)

  for (i in 1:objects_sub_n) {

    taxon.names[i] = paste0(objects.sub[[i]]$taxon.name, "_", objects.sub[[i]]$subTaxon.name)

    reads.count[,i] = apply(objects.sub[[i]]$readsCount.rmOut,1,mean)
    gene_length[,i] = objects.sub[[i]]$gene.lengths

    meanRPKM[,i] = apply(objects.sub[[i]]$rpkm.rmOut,1,mean)

  }

  boot.tree <- vector("list",B)

  progbar <- txtProgressBar(style = 3)

  y <- gene_n

  for (n in 1:B) {

    gene_index <- unlist(sample(y, replace = T))

    if (method == "gu2013") {

      reads.count.samp <- reads.count[gene_index,]
      gene_length.samp <- gene_length[gene_index,]

      omega.samp <- estomega.sample(objects.sub,gene_index)

      dis.mat <- dist.gu2013(reads.count.samp, gene_length.samp, omega.samp)

      #browser()
    }


    if (method == "brownian") {

      reads.count.samp <- reads.count[gene_index,]
      gene_length.samp <- gene_length[gene_index,]

      dis.mat <- dist.brownian(reads.count.samp, gene_length.samp)


    }

    if (method == "rho") {

      meanRPKM.samp <- meanRPKM[gene_index,]

      dis.mat <- dist.rho(meanRPKM.samp)

    }


    if (method == "euc") {

      meanRPKM.samp <- meanRPKM[gene_index,]

      dis.mat <- dist.euc(meanRPKM.samp)

    }

    if (method == "cos") {

      meanRPKM.samp <- meanRPKM[gene_index,]

      dis.mat <- dist.cos(meanRPKM.samp)

    }


    if (method == "jsd") {

      meanRPKM.samp <- meanRPKM[gene_index,]

      dis.mat <- dist.jsd(meanRPKM.samp)

    }

    row.names(dis.mat) = taxon.names
    colnames(dis.mat) = taxon.names

    #browser()
    
    if (!is.null(rooted))
      boot.tree[[n]] <- root(nj(dis.mat),rooted)
    else
      boot.tree[[n]] <- nj(dis.mat)


    setTxtProgressBar(progbar, n/B)

  }

  close(progbar)

  message(paste0(date(),": calculating bootstrap values..."))

  #browser()

  if (!is.null(rooted)) {

    pp <- prop.part(boot.tree)
    ans <- prop.clades(phy, part = pp, rooted = !is.null(rooted))

  } else {

    phy <- reorder(phy, "postorder")
    ints <- phy$edge[,2] > Ntip(phy)
    ans <- countBipartitions(phy, boot.tree)
    ans <- c(B, ans[order(phy$edge[ints, 2])])

  }

  if (trees) {
    class(boot.tree) <- "multiPhylo"
    ans <- list(BP = ans, trees = boot.tree)
  }

  message(paste0(date(), ": done bootstapping"))

  ans

}
