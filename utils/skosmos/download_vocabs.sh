#!/usr/bin/env sh

#!/bin/bash
#

TARGET="${TARGET:-localhost:3030}"

curl -L -o stw.ttl.zip http://zbw.eu/stw/version/latest/download/stw.ttl.zip
unzip -o stw.ttl.zip
curl -I -X POST -H Content-Type:text/turtle -T stw.ttl -G $HOSTNAME/skosmos/data --data-urlencode graph=http://zbw.eu/stw/
curl -L -o unescothes.ttl http://skos.um.es/unescothes/unescothes.ttl
curl -I -X POST -H Content-Type:text/turtle -T unescothes.ttl -G $HOSTNAME/skosmos/data --data-urlencode graph=http://skos.um.es/unescothes/

# wget from github and store CBS vocabulary in ./config/cbs-variables-thesaurus.ttl
curl -X 'GET' \
    'https://raw.githubusercontent.com/odissei-data/vocabularies/main/cbs/cbs-variables-thesaurus-20230310.ttl' \
    -H 'accept: application/xml' > cbs-variables-thesaurus.ttl
curl -I -X POST -H Content-Type:text/turtle -T cbs-variables-thesaurus.ttl -G $HOSTNAME/skosmos/data --data-urlencode graph=http://cbs.nl/variables/

# ellst
echo "getting ELLST vocab"
wget 'https://thesauri.cessda.eu/rest/v1/elsst-3/data?format=text/turtle' --output-document=ELSST.ttl
curl -I -X POST -H Content-Type:text/turtle -T ELSST.ttl -G $HOSTNAME/skosmos/data --data-urlencode graph=https://thesauri.cessda.eu/elsst/

# cessda topic classification
echo "getting topic classification"
curl 'https://vocabularies.cessda.eu/v2/vocabularies/TopicClassification/4.2.2?languageVersion=en-4.2.2_nl-4.2.2' -o TopicClassification.rdf
rapper TopicClassification.rdf --output turtle > TopicClassification.ttl
curl -I -X POST -H Content-Type:text/turtle -T TopicClassification.ttl -G $HOSTNAME/skosmos/data --data-urlencode graph=https://vocabularies.cessda.eu/vocabulary/TopicClassification

echo "getting general data format"
wget 'https://vocabularies.cessda.eu/v2/vocabularies/GeneralDataFormat/2.0.3?languageVersion=en-2.0.3_nl-2.0.3' | tr -d '\000' > GeneralDataFormat.rdf
rapper GeneralDataFormat.rdf --output turtle > GeneralDataFormat.ttl
curl -I -X POST -H Content-Type:text/turtle -T GeneralDataFormat.ttl -G $HOSTNAME/skosmos/data --data-urlencode graph=https://vocabularies.cessda.eu/vocabulary/GeneralDataFormat

# Analysis unit
echo "Getting analysis unit vocab"
curl 'https://vocabularies.cessda.eu/v2/vocabularies/AnalysisUnit/2.1.3?languageVersion=en-2.1.3_nl-2.1.3' | tr -d '\000' > AnalysisUnit.rdf
rapper AnalysisUnit.rdf --output turtle > AnalysisUnit.ttl
curl -I -X POST -H Content-Type:text/turtle -T AnalysisUnit.ttl -G $HOSTNAME/skosmos/data --data-urlencode graph=https://vocabularies.cessda.eu/vocabulary/AnalysisUnit

# Time method
echo "Getting time method vocab"
curl 'https://vocabularies.cessda.eu/v2/vocabularies/TimeMethod/1.2.3?languageVersion=en-1.2_nl-1.2.3' | tr -d '\000' > TimeMethod.rdf
rapper TimeMethod.rdf --output turtle > TimeMethod.ttl
curl -I -X POST -H Content-Type:text/turtle -T TimeMethod.ttl -G $HOSTNAME/skosmos/data --data-urlencode graph=https://vocabularies.cessda.eu/vocabulary/TimeMethod

# Sampling Procedure
echo "getting sampling procedure vocab"
#curl -X 'GET' \
#     'https://vocabularies.cessda.eu/v2/vocabularies/SamplingProcedure/1.1.4?languageVersion=en-1.1.4_nl-1.1.4' \
#     -H 'accept: application/xml' > SamplingProcedure.rdf
curl 'https://vocabularies.cessda.eu/v2/vocabularies/SamplingProcedure/1.1.4?languageVersion=en-1.1.4_nl-1.1.4' | tr -d '\000' > SamplingProcedure.rdf
rapper SamplingProcedure.rdf --output turtle > SamplingProcedure.ttl
curl -I -X POST -H Content-Type:text/turtle -T SamplingProcedure.ttl -G $HOSTNAME/skosmos/data --data-urlencode graph=https://vocabularies.cessda.eu/vocabulary/SamplingProcedure

# Type of Instrument
echo "getting type of instrument vocab"
curl 'https://vocabularies.cessda.eu/v2/vocabularies/TypeOfInstrument/1.1.4?languageVersion=en-1.1.4_nl-1.1.4' | tr -d '\000' > TypeOfInstrument.rdf
rapper TypeOfInstrument.rdf --output turtle > TypeOfInstrument.ttl
curl -I -X POST -H Content-Type:text/turtle -T TypeOfInstrument.ttl -G $HOSTNAME/skosmos/data --data-urlencode graph=https://vocabularies.cessda.eu/vocabulary/TypeOfInstrument

# Data Source Type
echo "getting data source type vocab"
#curl -X 'GET' \
#     'https://vocabularies.cessda.eu/v2/vocabularies/DataSourceType/1.0.2?languageVersion=en-1.0.2_nl-1.0.2' \
#     -H 'accept: application/xml' > DataSourceType.rdf
curl 'https://vocabularies.cessda.eu/v2/vocabularies/DataSourceType/1.0.2?languageVersion=en-1.0.2_nl-1.0.2' | tr -d '\000' > DataSourceType.rdf
rapper DataSourceType.rdf --output turtle > DataSourceType.ttl
curl -I -X POST -H Content-Type:text/turtle -T DataSourceType.ttl -G $HOSTNAME/skosmos/data --data-urlencode graph=https://vocabularies.cessda.eu/vocabulary/DataSourceType

 # Summary statistics
 echo "getting summary statistics vocab"
#curl -X 'GET' \
#     'https://vocabularies.cessda.eu/v2/vocabularies/SummaryStatisticType/2.1.2?languageVersion=en-2.1.2_nl-2.1.2' \
#     -H 'accept: application/xml' > SummaryStatistics.rdf
curl 'https://vocabularies.cessda.eu/v2/vocabularies/SummaryStatisticType/2.1.2?languageVersion=en-2.1.2_nl-2.1.2' | tr -d '\000' > SummaryStatistics.rdf
rapper SummaryStatistics.rdf --output turtle > SummaryStatistics.ttl
curl -I -X POST -H Content-Type:text/turtle -T SummaryStatistics.ttl -G $HOSTNAME/skosmos/data --data-urlencode graph=https://vocabularies.cessda.eu/vocabulary/SummaryStatistics

# Mode of Collection
echo "getting mode of collection vocab"
#curl -X 'GET' \
#     'https://vocabularies.cessda.eu/v2/vocabularies/ModeOfCollection/4.0.3?languageVersion=en-4.0.3_nl-4.0.3' \
#     -H 'accept: application/xml' > ModeOfCollection.rdf
curl 'https://vocabularies.cessda.eu/v2/vocabularies/ModeOfCollection/4.0.3?languageVersion=en-4.0.3_nl-4.0.3' | tr -d '\000' > ModeOfCollection.rdf
rapper ModeOfCollection.rdf --output turtle > ModeOfCollection.ttl
curl -I -X POST -H Content-Type:text/turtle -T ModeOfCollection.ttl -G $HOSTNAME/skosmos/data --data-urlencode graph=https://vocabularies.cessda.eu/vocabulary/ModeOfCollection

echo "Checking search index..."
curl "${SKOSMOS}/rest/v1/search?vocab=stw&query=a*"
