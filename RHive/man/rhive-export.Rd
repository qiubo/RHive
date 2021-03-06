\name{rhive-export}
\alias{rhive.export}
\alias{rhive.exportAll}
\alias{rhive.assign}
\alias{rhive.rm}
\alias{rhive.script.export}
\alias{rhive.script.unexport}
\title{Export R function to Hive using functions in Package `RHive'}
\usage{
rhive.export(exportname, hiveclient=rhive.defaults('hiveclient'), port = 6311, pos = -1, envir = .rhiveExportEnv, limit = 104857600)
rhive.exportAll(exportname, hiveclient=rhive.defaults('hiveclient'), port = 6311, pos = 1, envir = .rhiveExportEnv, limit = 104857600)
rhive.assign(name,value)
rhive.rm(name)
rhive.script.export(exportname, mapper = NULL, reducer = NULL, mapper_args=NULL, reducer_args=NULL, buffersize=-1L, hdfs = rhive.hdfs.defaults('hdfs'))
rhive.script.unexport(exportname, hdfs = rhive.hdfs.defaults('hdfs'))
}
\description{
Export R function to Hive using functions in Package `RHive'
}
\details{
RHive supports the following additional Hive functions. One is RUDF and
its syntax is \code{R(export-R-function-name,arguments,...,return-type)}.

Another is RUDAF and its syntax is \code{RA(export-R-function-name,arguments,...)}.
R function which runs via RUDAF should be made with the following rule.
This rule is a function naming rule. An R aggregation function is composed of 4 sub-functions and
each sub-function has a naming rule. First sub-function uses user-defined name, which is export-R-function-name. 
Second is made from combining first sub-function name and '.partial'.
Third is made from combining first function name and '.merge'. 
Final function is made from combining first name and '.terminate'.

UDTF is a built-in table-generating function in Hive. 
RHive supports two kinds of UDTF, unfold and expand. 
'unfold' syntax is \code{unfold(value,col1-v,col2-v,...,delim) as (col1,col2,...)}.
this 'unfold' function allows user to change one column into many columns.
'expand' syntax is \code{expand(value,col-v,delim) as(col)}.
this 'expand' function allows user to change one column into many rows.
}
\arguments{
\item{exportname}{function name to be exported.}
\item{limit}{total exported object size. default is 100MB}
\item{name}{a variable name, given as a character string.} 
\item{value}{a value to be assigned to 'name'}
\item{pos}{where to do the assignment.}
\item{envir}{the 'environment' to use.}
\item{port}{port of Rserve.}
\item{hiveclient}{a client for hive.}
\item{mapper}{R object as map function or Hive query.}
\item{reducer}{R object as reducer function.}
\item{buffersize}{streaming buffer size.}
\item{hdfs}{a client for hdfs.}
\item{mapper_args}{mapper custom environment.}
\item{reducer_args}{reducer custom environment.}
} 
\author{
\email{rhive@nexr.com}
}
\examples{
## try to connect hive server
\dontrun{rhive.connect("127.0.0.1")}

## execute HQL(hive query)
\dontrun{rhive.query("select * from emp")}


## define R function
\dontrun{coff <- 5.2}
\dontrun{scoring <- function(sal) {
	coff * sal
}}

## assign R object to Hive
\dontrun{rhive.assign('scoring',scoring)}
\dontrun{rhive.assign('coff',coff)}

## export R objects (scoring and coff) to Hive 
\dontrun{rhive.exportAll('scoring')}

## execute HQL using exported R objects
## name of UDF is 'R'
\dontrun{rhive.query("select R('scoring',sal,0.0) from emp")}

## delete R object in .rhiveExportEnv
\dontrun{rhive.rm('scoring')}
\dontrun{rhive.rm('coff')}

## define R aggregation function
## define iterate operator
\dontrun{hsum <- function(prev,sal) {
     if(is.null(prev))
	     sal
     else
	     prev + sal
}}
## define partial aggregation operator
\dontrun{hsum.partial <- function(agg_sal) {
	agg_sal
}}
## define merge operator
\dontrun{hsum.merge <- function(prev, agg_sal) {
     if(is.null(prev))
        agg_sal
     else
	prev + agg_sal
}}
## define final aggregation operator
\dontrun{hsum.terminate <- function(agg_sal) {
	agg_sal
}}

\dontrun{rhive.assign('hsum',hsum)}
\dontrun{rhive.assign('hsum.partial',hsum.partial)}
\dontrun{rhive.assign('hsum.merge',hsum.merge)}
\dontrun{rhive.assign('hsum.terminate',hsum.terminate)}
\dontrun{rhive.exportAll('hsum')}

## name of UDAF is 'RA'
\dontrun{rhive.query("select RA('hsum',sal) from emp group by empno")}


## export/unexport user define map/reduce script
\dontrun{
map <- function(k,v) {

      if(is.null(v)) {
         put(NA,1)
      }
      lapply(v, function(vv) {
         lapply(strsplit(x=vv,split ="\t")[[1]], function(w) put(paste(args,w,sep=""),1))
      })
  
 }

reduce <- function(k,vv) {
 
     put(k,sum(as.numeric(vv)))
  
}

mrscript <- rhive.script.export("scripttest",map,reduce)


rhive.query(paste("from (from emp MAP ename,position USING '", mrscript[1], "' as position,one cluster by position) map_output REDUCE map_output.aa,map_output.bb USING '", mrscript[2], "' as position,count",sep=""))

}

## close connection
\dontrun{rhive.close()}
}
\keyword{programming}
