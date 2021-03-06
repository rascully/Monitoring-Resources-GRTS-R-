 #This script includes the following functions:
 #   strat.pnl.setup.fcn ...  prompts user for information to set up strata 
 #          & panels and calls strat.panel.fcn 
 #    strat_panel.fcn.... defines strata & panels and assigns sites 
 #    ms.panel.fcn....  creates panels within strata.  Called by strat.panel.fcn
 #    ms.legacy.panel.fcn ....creates panels within strata and incorporates
 #        legacy points 
 #    rho.rxy.fcn....if strata are defined, the MS target sites are re-ordered 
 #          using hierarchical randomization.  This function invokes the HR
 #      trnrot01.scl.fcn....scales coordinates to the unit square and rotates 
 #      axes to provide maximal coverage in unit square,i.e., both x and y 
 #      ranges are very nearly (0,1) 
 #    fin.pop.rotate.fcn...rotates coordinates for a finite population
 #    rot.ax.fcn....axes rotation functioj called by fin.pop.rotate.fcn
 #    hirand.fcn...hierarchical randomization function
 #    wve.addr.fcn...creates quadrant recursive address via bit weaving
 #    four.2.10.fcn...converts base 4 address to base 10
 #
 #    modified 7/19/2012 to permit panel size = 0
           
 ####  function to create call to strat_panel.fcn

strat.pnl.setup.fcn <- function() 
{
  # Revised 9/28/11 to parse weight column for weight type (number, length, area)
  # and weight units (none, "m","km", "ft","mi", "m2","km2", "ft2", "mi2")
   
  YN.list <- c("Yes", "No")
  rernd <- NULL
  
  # get weight, x, and y column names
  write("Name of Master Sample csv file", file = stdout())
  dfrm.nam <- scan(file = "", what ="", n=1)
  dfrm <- read.csv(dfrm.nam)
  wtcol <- grep("w.t", names(dfrm), ignore.case = TRUE)

  if (length(wtcol) > 0) 
  {  
    wgt.nam <- select.list(choices = c(names(dfrm)[wtcol], "other"), title = "Column name for sampling weight")
  }

  if (length(wtcol) == 0 | wgt.nam == "other" )
  {
    write("Column name for sampling weight", file = stdout())
    wgt.nam <-  scan(file = "", what = "", n = 1)
  }

  if (!wgt.nam %in% names(dfrm))
  {
    write(paste("Weight column", wgt.nam, "not found"), file = stdout())
    return
  } 
  
  unit.lst <- c( "m","km", "ft","mi", "m2","km2", "ft2", "mi2")
  tmp <- unlist(lapply(sapply(unit.lst, grep, wgt.nam, ignore.case=TRUE, simplify=TRUE),length))
  
  if (all(tmp == 0)) 
    wgt.un <- "Number"

  wgt.un <- unit.lst[max(which(tmp > 0))]
  wgt.typ <- c("Number", rep("Length",4), rep("Area",4))[max(which(tmp> 0)) + 1]

  ############################################################################
  #  STRATA
  ############################################################################
  
  str.flg <- select.list(YN.list, title = "Define Strata?")
  
  if (str.flg == "Yes") 
  {
    dta.flg <- select.list(YN.list, title = "Stratum Column in Data?")
    
    if (dta.flg == "Yes")
    {
      write("Column name", file = stdout())
      strat_name <- scan(file = "", what = "", n=1)
      
      if (strat_name %in% names(dfrm))
      {
        strat_var <- as.character(dfrm[[strat_name]])
        strat <- sort(unlist(unique(strat_var)))
        num_strat <- length(strat)
      } 
      else 
      {                                           
         msg <- paste("Stratification column", strat_name, "not found")
         return(msg)
      }   
    } 
    else 
    {
      msg <- "Stratification column must be in the csv file" 
      return(msg)
    }
  } 
  else 
  {
    # no stratification, set strat_name to NULL
    strat_name <- NULL
    strat <- "None"
    num_strat <- 1
  }
  
  trgt.psz <- vector("list", num_strat)
  
  names(trgt.psz) <- strat
  
  # trgt.psz is a list who's components are have names that correspond to the strat values
  
  ############################################################################
  #  PANELS
  ############################################################################
  
  pnl.flg <- select.list(YN.list, title = "Panels?")
  
  if (pnl.flg == "Yes") 
  {
    if (is.null(strat_name) ) 
    {
      # no strata, but have panels, so get number of samples in each panel
      write("Number of panels?", file = stdout())
      npnl <- scan(file = "", what = integer(1),n=1)
      trgt.psz <- list(None = numeric(npnl))
      
      for (i in 1:npnl)
      {
        write(paste("Number of samples for Panel", i),file = stdout())
        trgt.psz$None[i] <- scan(file = "",what = integer(1),n=1)
      }
    } 
    else
    {
      # have both strata & panels, so get # panels & samples per panel in each stratum
      for(ns in 1:num_strat) 
      {
        write(paste("Number of panels in stratum", strat[ns],"?"), file = stdout())
        npnl <- scan(file = "", what = integer(1),n=1)
        
        if (npnl == 0) 
        {
          trgt.psz[[strat[ns]]] <- 0
        } 
        else 
        {  
          trgt.psz[[strat[ns]]] <- numeric(npnl)
          
          for (i in 1:npnl)
          {
            write(paste("Number of samples for stratum ",strat[ns], "Panel", i), file = stdout())
            trgt.psz[[strat[ns]]] [i] <- scan(file = "",what = integer(1),n=1)
          }
        }
      }
    }
  } 
  else 
  {
    # no panels, so get sample size (s) for strata if any
    if (is.null(strat_name)) 
    {
      # no strata or panels, so just need number of samples
      write("Number of samples?", file = stdout())
      trgt.psz[["None"]] <- scan(file = "", what = integer(1),n=1)
    } 
    else 
    {
      # strata but no panels, so get number of samples in each stratum
      npnl <- 1
      trgt.psz <- vector("list", num_strat)
      names(trgt.psz) <- strat

      for(ns in 1:num_strat) 
      {
        write(paste("Number of samples for stratum",strat[ns]), file = stdout())
        trgt.psz[[strat[ns]]]  <- scan(file = "",what = integer(1),n=1)
      }
    }
  }

  ############################################################################
  #  VARIABLE PROBABILITY
  ############################################################################

  vp.flg <- select.list(YN.list, title = "Variable Probability Sample?")
  
  if (vp.flg == "Yes") 
  {
    dta.flg <- select.list(YN.list, title = "Probability Column in Data?")
    
    if (dta.flg == "Yes")
    {
      write("Column name", file = stdout())
      prob.name <- scan(file = "", what = "",n=1)
      
      if (!(prob.name %in% names(dfrm)))
      {
        write(paste("Probability column", prob.name, "not found"), file = stdout())
        return(msg)
      }
    } 
    else 
    {
      write("Probability column must be in data" )
      return(msg)
    }
  } 
  else 
  {
    prob.name <- NULL
  }

  if (is.null(strat_name)) 
  {
    rernd.flg <- select.list(YN.list, title = "Re-randomize site list?", preselect = "No")
    
    if (rernd.flg == "Yes") 
      rernd <- TRUE 
    else 
      rernd <- NULL
  }

  ############################################################################
  #  LEGACY POINTS
  ############################################################################
  
  leg.flg <- select.list(YN.list, title ="Are legacy points to be included?")

  if (leg.flg == "Yes") 
  {
    write("Name of legacy point csv file", file = stdout())
    leg.nam <- scan(file = "", what ="", n=1)
    legacy.df <- read.csv(leg.nam)
    
    write("Should sample be ordered with legacy points first?" ,file = stdout())
    oldf <- select.list(YN.list, title = "Legacy points first?")
  
    if (oldf == "Yes") 
    {
      leg.first = TRUE 
    } 
    else
    {
      leg.first <- FALSE
    }
    
    if (!is.null(prob.name)) 
    {
      if (!(prob.name %in% names(legacy.df)))
      {
        write(paste("Probability column",prob.name, "not found in legacy file"),
        file = stdout())
        return(msg)
      }
    }
  } 
  else 
  {
    legacy.df <- NULL
  }
  
  # INPUTS:
  
  # dfrm - loaded csv file of sites to process
  #   expects columns named 'site.id', 'x.coord', 'y.coord' plus stratify, weight, probability columns as set below
  # strat_name - (otpional) name of column to stratify on
  # wgt.nam - name of weight column
  # wgt.un - weight units (km, km2, etc. depending on weight type)
  # wgt.typ - weight type (Length, Area)
  # trgt.psz - (optional / required if strat_name is supplied) # of panels per each strata value
  # rernd - re-randomize site list (FALSE, TRUE)
  # prob.name - (optional) name of probability column (to support variable probability)
  # legacy.df - (optional) loaded csv file of legacy sites to include
  # leg.first - order sample with legacy sites first (FALSE, TRUE)
  
  # OUTPUTS:
  
  # Use.order - the order that the sites should be selected
  # Panel - the panel number
  # Over_sample - indicates whether the site was an oversample or not (o or 1)
  # Adj_wt - adjusted weight for the site (in the same units as input)
  # site.id, x.coord, y.coord, stratum, weight - from the input file
  
  # EXAMPLE:
  
  # dfrm<-read.csv('<path to input sample sites csv file>')
  # strat_name<-'stratum'
  # wgt.nam<-'weight'
  # wgt.un<-'km'
  # wgt.typ<-'Length'
  # trgt.psz<-list(None = 20)
  #   or
  # trgt.psz<-list("1" = c(10,15,20), "2" = 10, "3" = c(5,5)) # for example, 3 strata, different panel / # of sites per each
  # rernd<-FALSE
  # prob.name<-NULL
  # legacy.df<-NULL
  # leg.first<-FALSE
  # strat_panel.fcn(dfrm,strat_name=strat_name,wgt.nam = wgt.nam,wgt.un, wgt.typ, trgt.psz=trgt.psz,rernd=rernd,prob.name = prob.name, legacy.df=legacy.df, leg.first=leg.first)
  
  strat_panel.fcn(dfrm,
                  strat_name = strat_name,
                  wgt.nam = wgt.nam,
                  wgt.un, 
                  wgt.typ,
                  trgt.psz = trgt.psz,
                  rernd = rernd,
                  prob.name = prob.name, 
                  legacy.df = legacy.df,
                  leg.first = leg.first)
}                                                            

############################################################################

# This function assigns strata and panels to the data frame dfrm
# Revised 11/10/10 to re-randomize for stratified selection and revise
# some error checking
# Rerandomiztion can also be forced by setting rernd to "TRUE"
#  Revized 10/25/10 to call new version of panel fcn
# Revised 10/14/10 to allow for zero samples in a stratum (in effect, permits
#   non-target sites to be identified and dropped from frame)
# Revised 9/14/10 to get stratification information from column named
#   "strat_name" in dfrm
# Revised 9/10/10 to count unique values in column strat_name to determine
#   number of strata, and to defalut to 1 stratum if strat_var is NULL .  Also
#   changed the way the default trgt_psz is set up
# strat_name is the name of the column in dfrm  containing the stratum
#   classification; can be numeric or character. Can be NULL if only one stratum
# trgt.psz is the target number of sites in each panel/stratum combination
# trgt.psz can be a single number if all panels have the same size; otherwise,
#    it must be a list of vectors with each element of the list containing a
#    vector of panel sizes for a stratum.  If a list, then the names of the
#    list components must match names of unique values in strat_var.
#    trgt.psz can be 0 for a stratum, in which case stratum is dropped
# rernd is an option to force re-randomization.  Default of NULL will be set to
#   FALSE unless sample is statified.  Stratified samples will be re-randomized
#   after strata selection usless rernd is explicitly setr to FALSE
# Modfied 9/8/2011 to accommodate option to incorporate legacy points.  If 
#   legacy points are present, they must be in the data frame legacy.df.(Default
#    value of NULL indicates absence of  legacy points)  Data frame must include 
#   columns named "x.coord", "y.coord".  If strata are desired, the legacy data 
#   frame must include a column of strata assignments with the same name as the
#   "strat.name" column is the MS data frame.  Strata names must match strata 
#   names in the MS data frame. 
#   If panels are desired, legacy points must be assigned to panels with the 
#   assignment in legacy.df column named "Panels"
# Modified 9/28/11 to require validated weight column, type, and units

# dfrm = dataframe
# trgt.psz = target panel size
# wgt.nam = weight name
# wgt.un = weight unit 
# wgt.typ = weight type
# strat_name = stratum name
# rernd = rerandomize
strat_panel.fcn <- function(dfrm,
                            trgt.psz   = NULL,
                            wgt.nam    = "wgt_km",
                            wgt.un     = "km",
                            wgt.typ    = "Length",
                            strat_name = NULL,
                            rernd      = NULL,
                            prob.name  = NULL,
                            legacy.df  = NULL, 
                            leg.first  = FALSE,
                            oversamplePercent = NULL) 
{
  msg <- result <- NULL
  
  if (is.null(trgt.psz)) 
  {
    msg <- c(msg, "Must specify target panel size")
    return(msg)
  }
  
  if (is.null(strat_name))
  {
    num_strat <- 1
    strat <- "None"
    strat_var <- rep("None", nrow(dfrm))
  }
  else 
  {       
    strat_var <- as.character(dfrm[[strat_name]])
    strat <- unique(strat_var)                                      
    num_strat <- length(strat)
  }

  # set re-randomize option
  if (is.null(rernd)) 
  {
    if (num_strat > 1) 
      rernd <- TRUE  
    else 
      rernd <- FALSE
  }
  
  # check for 0 samples per stratum
  if (any(lapply(trgt.psz, sum) == 0)) 
  {
    idx <- which( lapply(trgt.psz, sum) == 0)
    zdx <-  match(names(trgt.psz)[idx], strat)
    strat <- strat[-zdx]
    num_strat <- num_strat - length(idx)
    trgt.psz <- trgt.psz[-idx]
  }
  
  # Identify columns for "site.id", "x.coord", and "y.coord" 
  req.col <- c("site.id", "x.coord", "y.coord")
  
  # Note: in grep, "." matches any single character
  tmp <-  sapply(req.col,grep, names(dfrm), ignore.case=TRUE, simplify=TRUE)
  
  if (any(lapply(tmp, length) == 0)) 
  {
    mdx <- which( lapply(tmp, length) == 0)
    msg <- paste("Could not find column for ", names(dfrm)[mdx]," in data frame")
    return(msg)
  }
  
  # check for multiple use of reserved names & try to resolve
  if (any(lapply(tmp, length) > 1)) 
  {
    mdx <- which( lapply(tmp, length) > 1)
    
    for (i in 1:length(mdx)) 
    {
      idx <- which(names(dfrm)[tmp[[mdx[i]]]]== req.col[mdx[i]])
      
      if(length(idx ==1))
      {
         tmp[[mdx[i]]] <- idx
         msg<- paste("Multiple columns contain the text", tolower(req.col[mdx[i]]))
         msg <- paste(msg, "Function will use column named", req.col[mdx[i]])
         warn <- c(warn, msg)
      } 
      else 
      {
        msg<- paste("Multiple columns contain the text", 
        tolower(req.col[mdx[i]]), " Strata/panel selection halted")
        return(msg)
      }
    }
  }
  
  tmp <- unlist(tmp)    
  names(dfrm)[tmp] <- req.col
  
  # pick the samples for the panels
  st.lst <- vector("list", num_strat )
  msg.lst <- character( num_strat )
  result <- vector("list", num_strat)
  
  # check for legacy points 
  if (is.null(legacy.df)) 
  {
    # step through strata & assign points to strats & panels using function ms.panel.fcn
    for(i in 1: num_strat) 
    {
      st.lst[[i]] <-ms.panel.fcn(dfrm[strat_var == strat[i],],
                                 trgt.psz = trgt.psz[[strat[i]]],
                                 wgt.nam = wgt.nam,
                                 wgt.un = wgt.un,
                                 wgt.typ = wgt.typ,
                                 prob.name = prob.name,
                                 rernd = rernd,
                                 oversamplePercent = oversamplePercent)
      
      msg.lst[i] <- paste(msg,"Stratum",strat[i],st.lst[[i]]$msg)
      result[[i]] <- list(Stratum=strat[i],Result=st.lst[[i]]$result)
    }
  } 
  else 
  {
    # have legacy points, so step through strata to assign points to strats & 
    # panels using function ms.legacy.panel.fcn 
 
    # Identify columns for  "site.id", "x.coord", and "y.coord" 
    req.col <- c( "site.id", "x.coord", "y.coord")
    
    # Note: in grep, "." matches any single character
    tmp <-  sapply(req.col,grep, names(legacy.df), ignore.case=TRUE, simplify=TRUE)
    
    if (any(lapply(tmp, length) ==0)) 
    {
      mdx <- which( lapply(tmp, length) == 0)
      msg <- paste("Could not find colum for ", names(legacy.df)[mdx]," in legacy data frame")
      return(msg)
    }

    # check for multiple use of reserved names & try to resolve

    if (any(lapply(tmp, length) > 1)) 
    {
      mdx <- which(lapply(tmp, length) > 1)

      for (i in 1:length(mdx)) 
      {
        idx <- which(names(legacy.df)[tmp[[mdx[i]]]] == req.col[mdx[i]])
        
        if (length(idx == 1))
        {
          tmp[[mdx[i]]] <- idx
          msg<- paste("Multiple columns in legacy data frame contain the text", tolower(req.col[mdx[i]]))
          msg <- paste(msg, "Function will use column named", req.col[mdx[i]])
          warn <- c(warn, msg)
        } 
        else 
        {
          msg<- paste("Multiple columns in legacy data frame contain the text", tolower(req.col[mdx[i]]), " Strata/panel selection halted")
          return(msg)
        }
      }
    }
    
    tmp <- unlist(tmp)    
    names(legacy.df)[tmp] <- req.col
    
    # strat_var_lg should never be "None", there is always a stratumid
    #if (num_strat ==1 ) 
    #{
    #  strat_var_lg <- rep("None", nrow(legacy.df))
    #}  
    #else 
    #{
      strat_var_lg <- as.character(legacy.df[[strat_name]])
    #}
    
    #if (!is.null(legacy.df)) 
    #{
    #  strat_var <- c(strat_var, as.character(legacy.df[[strat_name]])) # join 2 lists
    #}
    
    strat <- unique(c(strat_var, strat_var_lg))                                      
    num_strat <- length(strat)
    
    for (i in 1: num_strat) 
    {
      if (any(strat_var_lg == strat[i])) 
      {
        leg.df = legacy.df[strat_var_lg == strat[i],]
      } 
      else 
      {
        leg.df <- NULL
      }
      
      st.lst[[i]] <-ms.legacy.panel.fcn(ms.df = dfrm[strat_var == strat[i],],
                                        legacy.df = leg.df, 
                                        trgt.psz = trgt.psz[[strat[i]]],
                                        wgt.nam = wgt.nam, 
                                        prob.name = prob.name,
                                        leg.first = leg.first)
      
      msg.lst[i] <- paste(msg,"Stratum",strat[i],st.lst[[i]]$msg)
      result[[i]] <- list(Stratum=strat[i],Result=st.lst[[i]]$result)
    }
  }
  
  return(list(msg=msg.lst, result=result))
}     

############################################################################

#  revised 9/15/2011 to incorporate variable probability selection
#  revised 6/15/2011 to rotate MS points to get better spread over unit square
#  revised 12/10/2010 to add use order column
#  Revised 11/10/2010 to have option to force re-randomization
#  Option will automatically be set for stratified samples by strat_pnl_fcn
#  Revised 10/25/10 to re-randomize if over sample small or zero
#  Revised 9/10/10 to correct error msg assignment
#  revised 8/17/2010 to allow different sizes for each panel
#  function assigns panels to a Master Sample subset in ms.df
# trgt.psz is the vector of target panel sizes (or target sample size if only
#   one panel)
# prob.nam is the column in ms.df that contains relative inclusion
#   probabilities for the frame.  Default assumes equi-probable sample.
# returned value is a list with two components
# message  is any error or informative message
# result is data frame with the first three rows as follows:
#  result[,1] =  panel number
#  result[,2] = over sample indicator (0 = no, 1 = yes site is over sample site
#  result[,3] = adjusted weight based on panel size
# The remaining columns of reslt are copied from ms.df

ms.panel.fcn <- function(ms.df, trgt.psz, wgt.nam="wgt.km",wgt.un = "km", wgt.typ = "Length", prob.name = NULL,rernd = "FALSE", oversamplePercent = NULL) 
{
  msg <- rslt <- NULL
  wc <- grep(wgt.nam, names(ms.df), ignore.case= TRUE)
  
  if(length(wc) == 0) 
  {
    msg <- "Could not find weight column in data frame"
    return(list(msg=msg, result=rslt))
  } 
  
  npop <- nrow(ms.df)    
  n.pnl <- length(trgt.psz)

  # assign panels & over sample
  if(npop < sum(trgt.psz)) 
  {
    msg <- "panel size or number of panels is too large"
    return(list(msg = msg, result = rslt))
  }
  
  if(is.null(oversamplePercent) || is.na(oversamplePercent)){
    p4 <- ceiling(log(trgt.psz,4))
    
    p4.sz <- 4^p4
    
    if(any(p4.sz <= 1.5 * trgt.psz)) 
    {
      p4.sz[p4.sz <= 1.5*trgt.psz] <- 2*p4.sz[p4.sz <= 1.5*trgt.psz]
    }
  }
  else {
    p4.sz <- ceiling((1+oversamplePercent)*trgt.psz)  
  }
  
  if (sum(p4.sz) <=  npop) 
  {
    psz <- p4.sz
  } 
  else 
  {
    psz <- floor(npop*trgt.psz/sum(trgt.psz)  )
  }                                                                 
  
  ov.sz <- psz - trgt.psz
  
  if (any(ov.sz < 0.5*psz)| rernd|!is.null(prob.name)) 
  {
    xc <- grep("x.coord", names(ms.df), ignore.case=TRUE)
    yc <- grep("y.coord", names(ms.df), ignore.case=TRUE)
    
    if(length(yc)== 0 | length(xc) ==0 )
    {
      msg <- "Must have x & y coordinates named x.coord and y.coord"
      return(list(msg=msg, result=rslt))
    }
    
    ord <- rho.rxy.fcn(ms.df[,xc], ms.df[,yc])[,1]
    ms.df <- ms.df[ord,]
    
    rernd = TRUE
  }
  
  if (n.pnl == 1) 
    pnl.ind <- rep(0,psz) 
  else 
    pnl.ind <- rep(1:n.pnl, psz)
  
  pnl.num <- rep(1:n.pnl, psz)
  idx <- 1:n.pnl
  jdx <- 2*idx -1
  idx <- 2*idx
  ndx <- numeric(2*n.pnl)
  ndx[jdx] <- trgt.psz
  ndx[idx] <- ov.sz
  ov.ind <-  rep(rep(0:1, n.pnl),ndx)
  Use.order <- NULL
  rslt.nam <- c("Use.order","Panel","Over_sample", paste("Adj_wt(",wgt.typ,")",wgt.un,sep = ""))
  
  for(i in 1:n.pnl) 
    if (psz[i] > 0) Use.order <- c(Use.order, 1:psz[i])
  
  # calculate adjusted inclusion weight. this is based on the panel size and may require adjustment if over-sample sites are used
  
  if (is.null(prob.name)) 
  {
    pnl.kdx  <- 1:(sum(psz))    
    
    adj.wt <-  (ms.df[pnl.kdx,wc] *npop/(trgt.psz[pnl.num]) ) *(1-ov.ind)
    msg <- paste(msg, "Panels successfully assigned")
    
    if (rernd) 
      msg <- paste(msg, "Re-randomization applied")
    
    rslt <- data.frame(Use.order,pnl.ind, ov.ind, adj.wt,ms.df[pnl.kdx,])
    names(rslt)[1:4] <- rslt.nam
  } 
  else 
  {
    # split MS points into n.pnl segments w/size proportional to trgt.psz
    rslt <- NULL
    rslt.nam <- c("Use.order","Panel","Over_sample", paste("Adj_wt(",wgt.typ,")",wgt.un,sep = ""))
    nms <- nrow(ms.df) 
    np.per.pnl <- floor(nms*(trgt.psz/sum(trgt.psz)))
  
    # assign panels & over sample
    strt.pt <- 0
    
    for (np in 1:n.pnl) 
    {
      nms <- np.per.pnl[np]
      fdx <- strt.pt + 1:nms
      strt.pt <- strt.pt + nms                                     
      adj.wt <- ms.df[fdx,wc]*nrow(ms.df)/np.per.pnl[np]
      prb <- psz[np]*ms.df[fdx,prob.name]*adj.wt/sum(ms.df[fdx,prob.name]*adj.wt)

      # get HR order for points in panel target pop
      fx <- ms.df$x.coord[fdx]
      fy <- ms.df$y.coord[fdx]                                                         
      
      # Scale to unit square & get random offset
      scl.lst <- trnrot01.scl.fcn(fx, fy)
      nlev <- ceiling(log2(psz[np]))-1
      nlv2 <- 2^nlev
      cel.prb <- 10

      # partition so no more than 1 sample point per cell & Construct hierarchical
      # address for all points
      
      while (max(cel.prb) > 1) 
      {
        nlev <- nlev + 1
        nhadr <- wve.addr.fcn(cbind(scl.lst$xr, scl.lst$yr), nlev)+1
        addr <- four.2.10.fcn(nhadr-1, nlev)*4^nlev
        cel.prb <- tapply(prb,addr, sum)
      }                                        
 
      # Non-randomized addresses of points are in matrix nhadr
      
      #   pick points in panel
      rdx <- pick.pts.fcn(nhadr=nhadr,addr=addr, nms=nms,nsmp=psz[np] , 
      prb=prb,nop=0, old.pt=NULL) 
    
      # construct  reverse hierarchical order for over-sample points
      nlv4 <- ceiling(logb(ov.sz[np],4))
      rho <- matrix(0, 4^nlv4, nlv4)
      rv4 <- 0:3
      pwr4 <- 4.^(0.:(nlv4 - 1.))
      
      for (i in 1:nlv4) 
      {
        rho[, i] <- rep(rep(rv4, rep(pwr4[i], 4.)),pwr4[nlv4]/pwr4[i])
      }
      
      rho4 <- rho%*%matrix(rev(pwr4), nlv4, 1)

      # Place weighted points on line in reverse hierarchical order
      rh.ord <- unique(floor(rho4 * ov.sz[np]/4^nlv4)) + 1.
      ov.ind <-  rep(0:1, c(trgt.psz[np], ov.sz[np])) 
      smp.wt <-  adj.wt[rdx] *psz[np]/(trgt.psz[np]*prb[rdx])*(1-ov.ind)
      
      if (n.pnl == 1) 
        pnl.ind <- rep(0,psz) 
      else 
        pnl.ind <- rep(np, psz[np]) 
      
      tmp.df <- data.frame(pnl.ind, 1:psz[np],ov.ind, smp.wt, ms.df[fdx[rdx],])
      names(tmp.df)[1:4] <- rslt.nam    
      rslt <- rbind(rslt,tmp.df)
    }
  }
  
  return (list(msg=msg, result=rslt))
}

############################################################################

# Modified September 2011
#
# ms.df contains the sample downloaded from the Master Sample website.
#   Legacy sample points must be supplied in the data frame legacy.df.
#   
#
# legacy.df is the data frame of legacy points.  User must define strata 
#   (if any) and panel assignments (if panels are required). These must be in 
#   the same projection and units as used by the Master Sample.  Columns must 
#   include site.id","x.coord","y.coord"  consistent with ms.df.  If strata or 
#   panels are required, stratum column should have the same name as the ms.df 
#   stratum column, panel column should be names "Panel".  
#   The legacy points are assumed to be located on the stream network sampled 
#     the Master Sample.  They should have been selected using the same GIS
#     coverage as the MS.  
#
#
# trgt.psz is the vector of target panel sizes (or target sample size if only
#   one panel)
#
# prob.name is name of column in ms.df) that contains relative inclusion
#   probabilities for the frame.  Default assumes equi-probable sample.
#   If prob.name is set, prob.name must also be in legacy.df.  For
#   example, to select a sample with inclusion probability proportional to
#   stream order, both prob.name  should be set name of column with stream order
#   of the respective points
#
#
# Points with coordinates in legacy.df are included wp1.  Nearby points (in
#   hierarchical order ) have prob adjusted downward to compensate.
#
# Sample will be returned in reverse hierarchical order unless "leg.first"
#   is set to TRUE.  If leg.first is TRUE, legacy points will appear before new
#   points.
ms.legacy.panel.fcn <-function (ms.df, legacy.df, trgt.psz, wgt.nam="wgt.km", wgt.un = "km", wgt.typ = "Length", prob.name = NULL, leg.first = FALSE)
{
  wc <- grep(wgt.nam, names(ms.df), ignore.case = TRUE)
  
  if (length(wc) == 0) 
  {
    msg <- "Could not find weight column in data frame"
    return(list(msg=msg, result=rslt))
  }
  
  nms <- nrow(ms.df)
  
  if (is.null(legacy.df)) 
  {
    nop <- 0
  }
  else 
  {                                                      
    nop <- nrow(legacy.df)
  }
  
  npop <- nms + nop
  msg <- rslt <- NULL
  n.pnl <- length(trgt.psz)                                    

  if (n.pnl ==1& nop > 0) 
  {
    if (!("Panel" %in% names(legacy.df))) 
    {
      legacy.df <- data.frame(legacy.df, Panel = rep(1, nrow(legacy.df)))
    } 
    else 
    {
      legacy.df$Panel <- rep(1, nrow(legacy.df))
    }
  }
  
  if (is.null(legacy.df))
  {
    leg.per.pnl <- rep(0, length(trgt.psz))
  } 
  else 
  {
    legpnl <- factor(legacy.df$Panel, levels = 1:length(trgt.psz))
    leg.per.pnl <- as.numeric(table(legpnl))        
  }
  
  # split MS points into n.pnl segments w/size proportional to trgt.psz
  np.per.pnl <- floor(nms*(trgt.psz/sum(trgt.psz)))              
  tp.per.pnl <- leg.per.pnl +np.per.pnl
  
  if (any(tp.per.pnl < trgt.psz)) 
  {
    tp.alloc <- paste(tp.per.pnl, collapse="; ")
    psz.alloc <- paste(trgt.psz, collapse="; ")
    msg <- paste("panel size or number of panels is too large: Total Points available per panel (", tp.alloc, "). Points allocated (", psz.alloc, ")")
    return(list(msg = msg, result = rslt))
  }

  if (any(leg.per.pnl > trgt.psz)) 
  {
    msg <- "sample size must be at least as large as the number of legacy sites"
    return(list(msg = msg, result= rslt) )
  }
  
  p4 <- ceiling(log(trgt.psz,4))
  p4.sz <- 4^p4
  
  if (any(p4.sz <= 1.5*trgt.psz)) 
  {
    p4.sz[p4.sz <= 1.5*trgt.psz] <- 2*p4.sz[p4.sz <= 1.5*trgt.psz]
  }
  
  psz <- p4.sz
  
  if (any(psz >= tp.per.pnl))  
  {
    psz[p4.sz >= tp.per.pnl] <- tp.per.pnl[p4.sz >= tp.per.pnl]                      
  }
  
  ov.sz <- psz - trgt.psz
  ord <- rho.rxy.fcn(ms.df$x.coord, ms.df$y.coord)[,1]
  ms.df <- ms.df[ord,] 
  frame.len <- sum(ms.df[,wc])
  
  # assign panels & over sample
  strt.pt <- 0
  rslt <- NULL
  
  for (np in 1:n.pnl) 
  {
    if (psz[np] == 0) next  
    nms <- np.per.pnl[np]
    odx <- which(legacy.df$Panel == np )
    nop <- leg.per.pnl[np]                          
    npop <- tp.per.pnl[np]
    fdx <- strt.pt + 1:nms
    strt.pt <- strt.pt + nms
    
    adj.wt <- c(ms.df[fdx,wc]*nms/npop*nrow(ms.df)/np.per.pnl[np], rep(frame.len/npop, nop))
    old.pt <- c(rep(FALSE, nms), rep(TRUE, nop))
    
    if (is.null(prob.name)) 
    {
      prb <- rep(psz[np]/tp.per.pnl[np],npop)
    } 
    else 
    {
      prb <- psz[np]*c(ms.df[fdx,prob.name], legacy.df[odx,prob.name]) / sum(c(ms.df[fdx,prob.name],legacy.df[odx,prob.name]))
    }
  
    # get HR order for composite of legacy & MS points
    fx <- c(ms.df$x.coord[fdx], legacy.df$x.coord[odx])
    fy <- c(ms.df$y.coord[fdx], legacy.df$y.coord[odx])
                                                          
    # Scale to unit square & get random offset
    scl.lst <- trnrot01.scl.fcn(fx, fy)
    nlev <- ceiling(log2(psz[np]))-1
    nlv2 <- 2^nlev
    cel.prb <- 10

    # partition so no more than 1 sample point per cell & construct hierarchical
    # address for all points                               
    while(max(cel.prb) > 1) 
    {
      nlev <- nlev + 1
      nhadr <- wve.addr.fcn(cbind(scl.lst$xr, scl.lst$yr), nlev)+1
      addr <- four.2.10.fcn(nhadr-1, nlev)*4^nlev
      cel.prb <- tapply(prb,addr, sum)
    }                                        
 
    # Non-randomized addresses of points are in matrix nhadr

    # pick points in panel
    rdx <- pick.pts.fcn(nhadr=nhadr,addr=addr, nms=nms,nsmp=psz[np], prb=prb,nop=nop, old.pt=old.pt)

    # pick sample from points in panel

    rdx.smp <- pick.pts.fcn(nhadr = nhadr[rdx,],
                            addr = addr[rdx], 
                            nms = psz[np] - nop, 
                            nsmp = trgt.psz[np],
                            
                            nop = nop, 
                            prb = rep(trgt.psz[np]/psz[np], psz[np]), 
                            old.pt = old.pt[rdx])

    # construct  reverse hierarchical order for over-sample points
    nlv4 <- ceiling(logb(ov.sz[np],4))
    rho <- matrix(0, 4^nlv4, nlv4)
    rv4 <- 0:3
    pwr4 <- 4.^(0.:(nlv4 - 1.))
    
    if (nlv4 > 0)
    {    
      for (i in 1:nlv4) 
      {
        rho[,i] <- rep(rep(rv4, rep(pwr4[i], 4.)), pwr4[nlv4]/pwr4[i])
      }
    }
    
    rho4 <- rho%*%matrix(rev(pwr4), nlv4, 1)

    # Place weighted points on line in reverse hierarchical order
    rh.ord <- unique(floor(rho4 * ov.sz[np]/4^nlv4)) + 1.
    rdx <- c(rdx[rdx.smp], rdx[-rdx.smp][rh.ord])
    site <- c(levels(ms.df$site.id)[ms.df$site.id][fdx], levels(legacy.df$site.id)[legacy.df$site.id][odx])[rdx]
    x.coord <- c(ms.df$x.coord[fdx], legacy.df$x.coord[odx])[rdx]
    y.coord <- c(ms.df$y.coord[fdx], legacy.df$y.coord[odx])[rdx]
    stratum.id <- c(ms.df$stratumid[fdx], legacy.df$stratumid[odx])[rdx]
    weight <- c(ms.df$weight[fdx], legacy.df$weight[odx])[rdx]
    
    ov.ind <- rep(0:1, c(trgt.psz[np], ov.sz[np]))
    smp.wt <- adj.wt[rdx] *psz[np]/(trgt.psz[np]*prb[rdx])*(1-ov.ind)
    
    if (n.pnl == 1) 
      pnl.ind <- rep(0,psz) 
    else 
      pnl.ind <- rep(np, psz[np])
    
    tmp.df <- data.frame(Use_Order = 1:psz[np], Panel= pnl.ind, Legacy_pt=old.pt[rdx] ,Over_sample = ov.ind,Adj_wt_km= smp.wt, site.id=site, x.coord=x.coord, y.coord=y.coord, stratumid=stratum.id, weight=weight)
    
    if (leg.first) 
    { 
      tmp.df <- tmp.df[order(!tmp.df$Legacy_pt),]
    }       
    rslt <- rbind(rslt,tmp.df)
  }  # end of loop through panels
  
  # Remove the Legacy_pt column
  rslt <- subset(rslt, select = -c(Legacy_pt))
  #SampleDesignSnapshotRequestID, UseOrder, PanelNumber, OverSample, AdjustedWeight, SiteID, XCOORD, YCOORD, StratumID, Weight
  names(rslt)  <- c("Use.order", "Panel","Over_sample", paste("Adj_wt(",wgt.typ,")",wgt.un,sep = ""), "site.id", "x.coord", "y.coord", "stratumid", "weight")
  msg <- paste(msg, "Panels successfully assigned" )
  
  return(list(msg = msg, result = rslt))
}

############################################################################

#       Calculates a (random) scale factor and random x & y offsets
#       so that  0 < (x-xof)/rscl   , (y - yof)/rscl < 1.0
#
#       Offsets & scale factor are picked so that both the scaled x  scaled y
#       fills most of the range (0, 1)
#       Axes are rotated so that range(x) ~= range(y)

trnrot01.scl.fcn <- function(x, y) 
{
  th <- 1:90*pi/180
  rng.dff <- sapply(th, fin.pop.rotate.fcn, x,y)
  idx <- which(rng.dff == min(rng.dff))
  rxy <- rot.ax.fcn(cbind(x,y), th = th[idx], xc= 0.5, yc = 0.5)
  rnx <- range(rxy[,1])
  rny <- range(rxy[,2])
  xscl <- diff(rnx)/runif(1, .99, .995)
  yscl <- diff(rny)/runif(1, .99, .995)
  rscl <- max(xscl, yscl)/runif(1, .99, .995)
  xof <- rnx[1] - (1-xscl/xscl)*runif(1)
  yof <- rny[1] - (1-yscl/yscl)*runif(1)
  
  list(xof = xof, yof = yof, xscl = xscl, yscl = yscl, rscl = rscl, rngx = rnx, rgny = rny, th = th[idx], xr = (rxy[,1] - xof)/rscl, yr = (rxy[,2] - yof)/rscl)
}


fin.pop.rotate.fcn <- function(th,x,y) 
{
  rxy <- rot.ax.fcn(cbind(x,y), th = th, xc= 0.5, yc = 0.5)
  abs(diff(range(rxy[,1])) - diff(range(rxy[,2])))
}
     
############################################################################

# Scale & translate to unit square
# Rotate so range(x)  ~   range(y)

rho.rxy.fcn <- function (fx,fy)
{
  ID <- 1:length(fx)
  sclp <- trnrot01.scl.fcn(fx,fy)
  rx <- sclp$xr
  ry <- sclp$yr
  nlev <- 5
  nhadr <- wve.addr.fcn(cbind(rx, ry), nlev)+1
  addr <- four.2.10.fcn(nhadr-1, nlev)*4^nlev

  while (length(unique(addr)) < nrow(nhadr) & nlev <20) 
  {
    nlev <- nlev + 1
    nhadr <- wve.addr.fcn(cbind(rx, ry), nlev)+1
    addr <- four.2.10.fcn(nhadr-1, nlev)*4^nlev
  }
  
  # Randomize hierarchical addresses
  ranhadr <-hirand.fcn(nhadr, nlev)
  scl <- rev(4^(1:nlev))
  rord<- order(ranhadr%*%matrix(scl, nlev,1))
  fxrd <- rx[rord]
  fyrd <- ry[rord]

  # Construct reverse hierarchical order
  nlv4 <- ceiling(logb(length(rx),4))
  rho <- matrix(0, 4^nlv4, nlv4)
  rv4 <- 0:3
  pwr4 <- 4.^(0.:(nlv4 - 1.))

  for(i in 1:nlv4)
    rho[, i] <- rep(rep(rv4, rep(pwr4[i], 4.)),pwr4[nlv4]/pwr4[i])
  
  rho4 <- rho%*%matrix(rev(pwr4), nlv4, 1)

  # Put points in reverse hierarchical order & rescale to original coordinates
  rh.ord <- unique(floor(rho4 * length(fx)/4^nlv4)) + 1.
  rdx <- rord[rh.ord]
  cbind(ID= ID[rdx],x = fx[rdx], y = fy[rdx])
}

############################################################################

wve.addr.fcn <- function (pts, nlev)
{
  # returns the non-randomized base 4 hierarchical address for the
  # base 10 (x,y) coordinates in pts to level nlev
  nhadr <- matrix(0, dim(pts)[1], nlev)
  nlv2 <- 2^(nlev)
  x <- floor((pts[, 1])*nlv2)
  y <- floor((pts[,2])*nlv2)

  for (j in nlev:1)
  {
    nhadr[,j] <- 2 * (x %% 2) + y %% 2
    x <- x %/% 2
    y <- y %/% 2
  }
  
  nhadr
}

############################################################################

#  convets a base 4 number to a base 10 number

four.2.10.fcn <- function(mat4, ndgt)
{
  scl <- 1./(4.^(1.:ndgt))
  mat4 %*% matrix(scl, ndgt, 1.)
}

############################################################################

# does hierarchial randomization of base 4 addresses stored in adr.mat
#
# only first ncl digit positions are randomized; rest are returned
# unchanged

hirand.fcn <- function(adr.mat, ncl)
{
  radr.mat <- adr.mat
  
  if (ncl == 1.) 
  {
    perm <- sample(x = 4)
    radr.mat <- perm[adr.mat]
  }
  else 
  {
    perm <- sample(x = 4)
    radr.mat[, 1.] <- perm[adr.mat[, 1.]]
    
    for(i in 1:4) 
    {
      gp <- adr.mat[, 1.] == i
      if (any(gp))
        if (sum(gp) > 1.)
          radr.mat[gp, 2.:ncl] <- hirand.fcn(adr.mat[gp, 2.:ncl], ncl - 1)
        else 
          radr.mat[gp, 2.:ncl] <- sample(x=4., size=ncl - 1., replace = T)
    }
  }
  
  radr.mat
}

############################################################################

#  rotates coordinates in cords through angle theta (in radians) with
#    origin at (xc, yc)
#
# returns a data frame with new coodinates names "x" and "y"

rot.ax.fcn <- function(cords, theta = 0, xc = 0, yc = 0)
{
  sn <- sin(theta)
  cs <- cos(theta)
  cords[,1] <- cords[,1] - xc
  cords[,2] <- cords[,2] - yc
  xp <- cords[, 1.] * cs + cords[, 2.] * sn + xc
  yp <- cords[, 2.] * cs - cords[, 1.] * sn + yc
  data.frame(x = xp, y = yp)
}

############################################################################

pick.pts.fcn <- function(nhadr, addr, nms, nsmp, prb, nop=0, old.pt = NULL)  
{
  npop <- nms + nop
  ord <- order(addr)
  nrd.prb <- prb[ord]
                     
  # if have legacy pts, set up to select them with prob one
  if (nop > 0) 
  {
    old.idx <- (1:npop)[old.pt[ord]]
    ms.idx <- (1:npop)[!old.pt[ord]]

    # loop to locate adjacent points & adjust prob
    for (i in 1:length(old.idx)) 
    {
      jdx <- old.idx[i]
                                                  
      # jdx has index of old point. select points closest to current legacy point until get to prob total > 1

      tmp.idx <- ms.idx
      
      while (sum(nrd.prb[jdx])  < 1) 
      {
        pt.dif <- abs(tmp.idx - jdx[1])
        adx <- min(tmp.idx[which(pt.dif == min(pt.dif))])
        tmp.idx <- tmp.idx[-which(tmp.idx == adx)]
        jdx <- c(jdx,adx )
      }

      # for the last point added, back off so that total prob of points zeroed is exactly 1

      ovr.prb <- sum(nrd.prb[jdx]) -1
      nrd.prb[jdx] <-  0
      nrd.prb[jdx[length(jdx)]] <- ovr.prb

      if (any(nrd.prb[ms.idx] == 0))
      {
          ms.idx <- ms.idx[-which(nrd.prb[ms.idx] == 0)]
      }
    }
  
    nrd.prb[old.idx] <- 1
  }
   
  prb <- nrd.prb[order(ord)]

  # select points

  # construct randomized hierarchical addresses
  nlev <- ncol(nhadr)
  if (is.null(nlev))
  {
    nlev <- NCOL(nhadr)
  }
  ranhadr <-hirand.fcn(nhadr, nlev)
  scl <- rev(4^(1:nlev))
  rord<- order(ranhadr%*%matrix(scl, nlev,1))

  # Pick sample points

  rstrt <- runif(1)
  ttl.prb <- c(0, cumsum(prb[rord]))
  idx <- ceiling((ttl.prb - rstrt))
  smpdx <- numeric(nsmp)
  ndx <- 1.:length(ttl.prb)

  for(cmx in 1.:nsmp) 
  {
    smpdx[cmx] <- min(ndx[idx >= cmx]) - 1.
  }
  
  return(rord[smpdx])
}

