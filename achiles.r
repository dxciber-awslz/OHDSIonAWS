if(packageVersion("SqlRender") != "1.6.2"){devtools::install_github("ohdsi/SqlRender", ref = "v1.6.2", upgrade = "never")}
if(packageVersion("DatabaseConnector") != "2.2.0"){devtools::install_github("ohdsi/DatabaseConnector", ref = "v2.2.0", upgrade = "never")}
if(packageVersion("DatabaseConnectorJars") != "1.0.0"){devtools::install_github("ohdsi/DatabaseConnectorJars", ref = "v1.0.0", upgrade = "never")}
if(packageVersion("OhdsiRTools") != "1.7.0"){devtools::install_github("ohdsi/OhdsiRTools", ref = "v1.7.0", upgrade = "never")}
if(packageVersion("Achilles") != "1.6.3"){devtools::install_github("ohdsi/Achilles", ref = "v1.6.3", upgrade = "never")}
library(Achilles)
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "redshift",server = "ohdsi-poc-00-main-mastersta-redshiftclustersingle-p3bfecw3q3v4.c3wexsqarjf5.us-east-2.redshift.amazonaws.com/mycdm",
    user = "master",password = "W#ZWE_768_dmTxRrmmtycg5yd2Uwi_")
conn <- connect(connectionDetails)
dbSendStatement(conn, "CREATE TABLE synthea1kresults.cohort (cohort_definition_id INTEGER NOT NULL,subject_id INTEGER NOT NULL,cohort_start_date DATE NOT NULL,cohort_end_date DATE NOT NULL);")

cdmDatabaseSchema <- "CMSDESynPUF1k"
cohortDatabaseSchema <- "CMSDESynPUF1kresults"
achillesResults <- Achilles::achilles(connectionDetails,cdmDatabaseSchema = cdmDatabaseSchema,resultsDatabaseSchema = cohortDatabaseSchema,sourceName = cdmDatabaseSchema,createTable = TRUE,cdmVersion = "5",vocabDatabaseSchema = cdmDatabaseSchema)
								
cdmDatabaseSchema <- "CMSDESynPUF100k"
cohortDatabaseSchema <- "CMSDESynPUF100kresults"
achillesResults <- Achilles::achilles(connectionDetails,cdmDatabaseSchema = cdmDatabaseSchema,resultsDatabaseSchema = cohortDatabaseSchema,sourceName = cdmDatabaseSchema,createTable = TRUE,cdmVersion = "5",vocabDatabaseSchema = cdmDatabaseSchema)

cdmDatabaseSchema <- "synthea100k"
cohortDatabaseSchema <- "synthea100kresults"
achillesResults <- Achilles::achilles(connectionDetails,cdmDatabaseSchema = cdmDatabaseSchema,resultsDatabaseSchema = cohortDatabaseSchema,sourceName = cdmDatabaseSchema,createTable = TRUE,cdmVersion = "5",vocabDatabaseSchema = cdmDatabaseSchema)

cdmDatabaseSchema <- "synthea1k"
cohortDatabaseSchema <- "synthea1kresults"
achillesResults <- Achilles::achilles(connectionDetails,cdmDatabaseSchema = cdmDatabaseSchema,resultsDatabaseSchema = cohortDatabaseSchema,sourceName = cdmDatabaseSchema,createTable = TRUE,cdmVersion = "5",vocabDatabaseSchema = cdmDatabaseSchema)
