<#assign reportTableProperties = {
  FIELD.name           : {'columnName': 'Annotation name',                       "normalizerFun": csvTextNormalizer},
  FIELD.status         : {'columnName': 'Annotation status',                     "normalizerFun": csvTextNormalizer},
  FIELD.agreement      : {'columnName': 'Annotation - Agreement with applicant', "normalizerFun": csvTextNormalizer},
  FIELD.remarks        : {'columnName': 'Annotation - Evaluation remarks',       "normalizerFun": csvTextNormalizer},
  FIELD.entityName     : {'columnName': 'Entity name',                           "normalizerFun": csvTextNormalizer},
  FIELD.entityType     : {'columnName': 'Entity type',                           "normalizerFun": nonEmptyNormalizer},
  FIELD.entityID       : {'columnName': 'Entity UUID',                           "normalizerFun": nonEmptyNormalizer},
  FIELD.sectionNumber  : {'columnName': 'TOC Section name',                      "normalizerFun": csvTextNormalizer},
  FIELD.sectionName    : {'columnName': 'Section document name',                 "normalizerFun": csvTextNormalizer},
  FIELD.sectionDocType : {'columnName': 'Section document type',                 "normalizerFun": nonEmptyNormalizer},
  FIELD.docID          : {'columnName': 'Section document UUID',                 "normalizerFun": nonEmptyNormalizer},
  FIELD.docUrl         : {'columnName': 'URL',                                   "normalizerFun": csvTextNormalizer}
}>

<#function identity x>
  <#return x>
</#function>

<#function csvNormalizer textValue normalizerFun>
  <#if !(textValue?has_content)>
    <#-- Return "" -->
    <#return "\"\"">
  </#if>
  <#return normalizerFun(textValue)>
</#function>

<#function nonEmptyNormalizer textValue>
  <#return csvNormalizer(textValue, identity)>
</#function>

<#function normalizeQuotesAndNewlines textValue>
  <#local newValue = textValue>
  <#local newValue = newValue?replace("\"", "\"\"")>
  <#local newValue = newValue?replace("\n", "\\n")>
  <#return "\""+ newValue + "\"">
</#function>

<#-- Function that recieves a text value as input and return a new string escaped for .csv file (comma separated value)
  It replaces in the text every quotes (") character with two quotes ("")
  It puts the text into a "<text>" format -->
<#function csvTextNormalizer textValue>
  <#return csvNormalizer(textValue, normalizeQuotesAndNewlines)>
</#function>

<#macro produceColumnNameRow columnsOrdered>
  <#local headers = []>
  <#list columnsOrdered as col>
    <#local headers = headers + [reportTableProperties[col].columnName]>
  </#list>
  ${headers?join(",")}<#t>

</#macro>

<#macro produceRow rowHash columnsOrdered>
  <#local cells=[]>
  <#list columnsOrdered as field>
    <#local cells = cells + [normalizeValue(rowHash, field)]>
  </#list>
  ${cells?join(",") + '\n'}<#t>
</#macro>

<#function normalizeValue rowHash key>
  <#if !(rowHash[key]??)>
    <#stop rowHash?keys?join(' ')>
    <#stop 'Error: data table does contain field with key: ${key}'>
  </#if>
  <#local normalizer = reportTableProperties[key].normalizerFun>
  <#return normalizer(rowHash[key])>
</#function>

<#macro produceReport reportData metadata>
  <#local columnsOrdered = metadata.columnsOrdered>
  <#local csvDataTable = reportData[SINGLETON_IND][SINGLETON_IND]>
  <@produceColumnNameRow columnsOrdered/>
  <#list csvDataTable as rowHash>
    <@produceRow rowHash columnsOrdered/>
  </#list>
</#macro>
