<#assign dataTableProperties = {
  FIELD.nodeType             : {'columnName': 'Node type'},
  FIELD.entityName                   : {'columnName': 'Entity name'},
  FIELD.sectionName         : {'columnName': 'Section name'},
  FIELD.nodeName         : {'columnName': 'Node name'},
  FIELD.level         : {'columnName': 'Level'}
}>

<#macro produceColumnNameRow columnsOrdered>
  <#local headers = []>
  <#list columnsOrdered as col>
    <#local headers = headers + [dataTableProperties[col].columnName]>
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
  <#return rowHash[key]>
</#function>

<#macro produceReport reportData metadata>
  <#local csvDataTable = reportData[SINGLETON_IND][SINGLETON_IND]>
  <#local columnsOrdered = ((csvDataTable?first)!{})?keys>
  <#if metadata?has_content>
    <#local columnsOrdered = metadata.columnsOrdered>
  </#if>
  <@produceColumnNameRow columnsOrdered/>
  <#list csvDataTable as rowHash>
    <@produceRow rowHash columnsOrdered/>
  </#list>
</#macro>
