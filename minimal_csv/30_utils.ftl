<#include "10_constants.ftl">

<#-- Prints the textToken nr number of times -->
<#function getIndentationText nr textToken = '-'>
  <#local indentText = ''>
  <#list 1..nr as x>
    <#local indentText = indentText + textToken>
  </#list>
  <#return indentText>
</#function>

<#function addDocumentToSequenceAsUnique document sequence>
  <#if !(document?has_content)>
    <#return sequence>
  </#if>
  <#list sequence as doc>
    <#if document.documentKey == doc.documentKey>
      <#return sequence>
    </#if>
  </#list>
  <#return sequence + [document]>
</#function>

<#-- Gets a docSequence list of documents and a docKeyList list of keys. Returns a new list of documents that contain only those document whose keys did not appear in docKeyList -->
<#function removeDocumentWitKey docSequence docKeyList>
  <#if !(docSequence?has_content && docKeyList?has_content)>
    <#return docSequence>
  </#if>
  <#local newSequence = []>
  <#list docSequence as doc>
    <#if !(docKeyList?seq_contains(doc.documentKey))>
      <#local newSequence = newSequence + [doc]>
    </#if>
  </#list>
  <#return newSequence>
</#function>

<#-- Function to check if the docElementNode element node is a reference field and remember referenced entities
   for later traversal
   toTravereseList - a list with already identified entity documents for traversal
   traveresedKeyList - a list with document keys already traversed
   returns a new version of the toTravereseList -->
<#function checkAndRememberReferencedEntity docElementNode toTravereseList traveresedKeyList>
  <#if docElementNode?node_type == 'document_reference'>
    <#return checkAndRememberEntityKey(docElementNode, toTravereseList, traveresedKeyList) />
  </#if>
  <#if docElementNode?node_type == 'document_references'>
    <#local newToTraverseList = toTravereseList>
    <#list docElementNode as item>
      <#local newToTraverseList = checkAndRememberEntityKey(item, newToTraverseList, traveresedKeyList) />
    </#list>
    <#return newToTraverseList />
  </#if>
  <#return toTravereseList>
</#function>

<#-- Function to check whether the docKey is a refrence to an entity document and if it was not traversed yet,
  remember it for later traversal by returning a new list based on toTravereseEntityList
  toTravereseList - a list with already identified entity documents for traversal
  traveresedKeyList - a list with document keys already traversed
  returns a new version of the toTravereseList -->
<#function checkAndRememberEntityKey docKey toTravereseList traveresedKeyList>
  <#local doc = iuclid.getDocumentForKey(docKey) />
  <#if doc?has_content && isEntityDocument(doc) && !(traveresedKeyList?seq_contains(doc.documentKey))>
      <#return addDocumentToSequenceAsUnique(doc, toTravereseList)>
  </#if>
  <#return toTravereseList>
</#function>

<#-- List of IUCLID's entity types -->
<#assign entityTypes = ['SUBSTANCE', 'MIXTURE', 'TEMPLATE', 'ANNOTATION', 'ARTICLE', 'CATEGORY', 'CONTACT', 'LEGAL_ENTITY', 'LITERATURE', 'REFERENCE_SUBSTANCE', 'SITE', 'TEST_MATERIAL_INFORMATION']>

<#function isNulled x>
  <#if x?is_string && x == NULL_IND>
    <#return true>
  </#if>
  <#return false>
</#function>

<#-- Returns true if doc is a IUCLID entity -->
<#function isEntityDocument doc>
  <#return entityTypes?seq_contains(doc.documentType)>
</#function>

<#-- List of IUCLID's composite entity types -->
<#assign compositeEntityTypes = ['SUBSTANCE', 'MIXTURE', 'TEMPLATE']>

<#-- Returns true if doc is a IUCLID composite entity -->
<#function isCompositeEntityDocument doc>
  <#return compositeEntityTypes?seq_contains(doc.documentType)>
</#function>

<#function getInheritedTemplates entityDoc>
  <#--
  <#if !(mode?has_content && mode == 'PUBLISHING') && entityDoc.documentType == 'SUBSTANCE'>
    <#return entityDoc.inherited>
  </#if>
  -->
  <#return []>
</#function>

<#function getRelatedCategories entityDoc>
  <#if !(mode?has_content && mode == 'PUBLISHING')>
    <#local params={'key': [entityDoc.documentKey]}>
    <#return iuclid.query('iuclid6.SubstanceRelatedCategories', params, 0, 100)>
  </#if>
	<#return []>
</#function>

<#function getRelatedMixtures entityDoc>
  <#--
  <#if !(mode?has_content && mode == 'PUBLISHING')>
    <#local params={'key': [entityDoc.documentKey]}>
    <#return iuclid.query('iuclid6.SubstanceRelatedMixtures', params, 0, 100)>
  </#if>
   -->
	<#return []>
</#function>

<#-- `esc' built-in is available since FreeMarker 2.3.24. -->
<#-- Function that recieves a text value as input and return a new string escaped for .csv file (comma separated value)
  It replaces in the text every quotes (') character with two quotes ('')
  It puts the text into a '<text>' format -->
<#function escapeCsvText textValue>
  <#if !(textValue?has_content)>
    <#-- Return '' -->
    <#return '\'\''>
  </#if>
  <#local newValue = textValue>
  <#local newValue = newValue?replace('\'', '\'\'')>
  <#local newValue = newValue?replace('\n', '\\n')>
  <#return '\''+ newValue + '\''>
</#function>

<#-- Macro that prints the textValue in a csv escaped format -->
<#macro csvValue textValue>
<#compress>
${escapeCsvText(textValue)}
</#compress>
</#macro>

<#function getSectionName sectionNode>
  <#local sectionName = "">
  <#if sectionNode?has_content>
    <#if sectionNode.number?has_content>
      <#local sectionName = sectionNode.number + " ">
    </#if>
    <#local sectionName = sectionName + sectionNode.title>
  </#if>
  <#return sectionName>
</#function>

<#function getSectionNumber sectionNode>
  <#if sectionNode?is_hash && sectionNode.number?is_string && sectionNode.number?has_content>
    <#return sectionNode.number>
  </#if>
  <#return LEVELNAME.COMPOSITE_ENTITY>
</#function>

<#function getDocumentUrl document>
  <#local generatedUrl = iuclid.webUrl.entityView(document.documentKey) />
  <#if generatedUrl?has_content>
    <#-- Get the base URL part -->
    <#local generatedUrl = generatedUrl?keep_before('/iuclid6-web') />
  </#if>
  <#return generatedUrl + '/iuclid6-web/?key=' + document.documentKey>
</#function>

<#function getPhraseCodeValue phraseCode includeDescription=false locale="en">
  <#local displayText = "" />
  <#local localizedPhrase = iuclid.localizedPhraseDefinitionFor(phraseCode, locale) />
  <#if localizedPhrase?has_content>
    <#local displayText = localizedPhrase.text />
    <#if includeDescription && localizedPhrase.description?has_content>
      <#local displayText = displayText + " [" + localizedPhrase.description + "]" />
    </#if>
  </#if>
  <#return displayText>
</#function>

<#function getPicklistFieldAsText picklistValue includeDescription=false locale='en'>
  <#if !picklistValue?has_content>
    <#return ''/>
  </#if>
  <#local localizedPhrase = iuclid.localizedPhraseDefinitionFor(picklistValue.code, locale) />
  <#if !localizedPhrase?has_content>
    <#return ''/>
  </#if>
  <#local displayText = localizedPhrase.text />
  <#if localizedPhrase.open && picklistValue.otherText?has_content>
    <#local displayText = displayText + ' ' + picklistValue.otherText />
  </#if>
  <#if includeDescription && localizedPhrase.description?has_content>
    <#local displayText = displayText + ' [' + localizedPhrase.description + ']' />
  </#if>
  <#return displayText>
</#function>

<#function getSectionDocType sectionDoc>
  <#local sectionDocType = sectionDoc.documentType>
  <#if !isEntityDocument(sectionDoc)>
    <#local sectionDocType = sectionDocType + '.' + sectionDoc.documentSubType>
  </#if>
  <#return sectionDocType>
</#function>
<#function getActiveSubstanceList mixture>
	  <#local compoundList = []/>

	  <#local compositionList = iuclid.getSectionDocumentsForParentKey(mixture.documentKey, 'FLEXIBLE_RECORD', 'MixtureComposition') />

	  <#list compositionList as composition>
		    <#local componentList = composition.Components.Components/>

		    <#list componentList as component>
			      <#if isComponentActiveSubstance(component)>
				        <#if component.Reference?has_content>
					          <#local compound = iuclid.getDocumentForKey(component.Reference)/>
					          <#if compound?has_content && compound.documentType=='SUBSTANCE' || compound.documentType=='MIXTURE'>
						            <#local compoundList = com.addDocumentToSequenceAsUnique(compound, compoundList)/>
					          </#if>
				        </#if>
			      </#if>
		    </#list>
	  </#list>
	  <#return compoundList />
</#function>

<#function isComponentActiveSubstance component>
	  <#return component.Function?has_content && com.picklistValueMatchesPhrases(component.Function, ['active substance']) />
</#function>

<#function getComponentList mixture>
	<#local fullComponentList = []/>
	<#local compositionList = iuclid.getSectionDocumentsForParentKey(mixture.documentKey, 'FLEXIBLE_RECORD', 'MixtureComposition') />

	<#list compositionList as composition>
	  <#if composition?has_content>
		  <#local componentList = composition.Components.Components/>
		  <#list componentList as component>
        <#local fullComponentList = fullComponentList + [component]>
		  </#list>
	  </#if>
	</#list>
	<#return fullComponentList />
</#function>

<#-- Snagged from existing code -->
<#function getActiveSubstanceList mixture>
    <#local mixtureComponents = getComponentList(mixture)>
	  <#local compoundList = []/>
    <#list mixtureComponents as component>
        <#if isComponentActiveSubstance(component)>
          <#local compound = iuclid.getDocumentForKey(component.Reference)/>
          <#local compoundList = com.addDocumentToSequenceAsUnique(compound, compoundList)/>
        </#if>
    </#list>
	  <#return compoundList />
</#function>

<#function getComponentKeyToFunctionHash mixture>
  <#local mixtureComponents = getComponentList(mixture)>
	<#local keyToFunctionHash = {}/>
  <#list mixtureComponents as component>
    <#local componentFunction = iuclid.localizedPhraseDefinitionFor(component.Function.code, 'en')>
    <#-- this potentially overwrites hash entries. Was: com.addDocumentToSequenceAsUnique(compound, compoundList) -->
    <#if componentFunction?has_content && componentFunction.text?has_content>
      <#local keyToFunctionHash = keyToFunctionHash + {component.Reference: componentFunction.text}/>
    </#if>
  </#list>
	<#return keyToFunctionHash />
</#function>

<#function getEntityDocumentKey document>
  <#return document.documentKey>
</#function>

<#function getActiveSubstanceKeyList mixture>
    <#return map(getEntityDocumentKey, getActiveSubstanceList(mixture))>
</#function>

<#function getComponentDocument component>
  <#return iuclid.getDocumentForKey(component.Reference) >
</#function>

<#function getComponentKeyList mixture>
  <#local componentDocs = map(getComponentDocument, getComponentList(mixture))>
  <#return map(getEntityDocumentKey, componentDocs)>
</#function>

<#-- TODO reuse common_module macro -->
<#function getTextForConfidentialityLegislations confidentialityLegislations>
  <#if !confidentialityLegislations?has_content>
    <#return "">
  </#if>
  <#local displayText = "" />
  <#list confidentialityLegislations as legislation>
    <#local legText = getPhraseCodeValue(legislation.code) />
    <#if legislation.otherText?has_content>
      <#local legText = legText + " " + legislation.otherText />
    </#if>
    <#local displayText = displayText + legText + "; " />
  </#list>
  <#return displayText>
</#function>

<#-------------------------------------------------->
<#-------------- Numerical helpers ----------------->
<#-------------------------------------------------->

<#function roundToPlaces number places>
  <#local tempNumber = number>
  <#list 1..places as _>
    <#local tempNumber = tempNumber * 10>
  </#list>
  <#local tempNumber = tempNumber?round>
  <#list 1..places as _>
    <#local tempNumber = tempNumber / 10>
  </#list>
  <#return tempNumber>
</#function>

<#function add a b>
  <#return a + b>
</#function>

<#function sum seq>
  <#return reduce(add, seq, 0)>
</#function>


<#-------------------------------------------------->
<#---- Primitive data transformation functions ----->
<#-------------------------------------------------->
<#-- Some to be deprecated with Freemarker 2.3.29 -->

<#function filterByKeyValue key value seq>
  <#local filtered = []/>
  <#list seq as hashElement>
    <#if hashElement[key] == value>
      <#local filtered = filtered + [hashElement] >
    </#if>
  </#list>
  <#return filtered>
</#function>

<#function first seq>
  <#return seq?first>
</#function>

<#function rest seq>
    <#if seq?size gt 0>
        <#return seq[1..]>
    </#if>
    <#return seq>
</#function>

<#-- select() subsets columns from a larger data table. -->
<#function select colSeq seq>
  <#local newTable = []>
  <#list seq as row>
    <#local newRow = {}>
    <#list colSeq as colName>
      <#local newRow = newRow + {colName: row[colName]}>
    </#list>
    <#local newTable = newTable + [newRow]>
  </#list>
  <#return newTable>
</#function>

<#-- grouping requires columns whose types are convertible to text-->
<#function groupBy keySeq seq shouldToString=false>
    <#local key = keySeq?first>
    <#local groupsHash = {}>
    <#list seq as hashEl>
      <#local keyVal = hashEl[key]>
      <#if !(keyVal?is_string) && !shouldToString>
        <#stop 'Value in' + key +
        'was not a string and did not try to interpolate (set shouldToString = true to try)'>
      </#if>
      <#local keyValGroup = groupsHash[keyVal]![]>
      <#local keyValGroup = keyValGroup + [hashEl]>
      <#local groupsHash = groupsHash + {keyVal: keyValGroup}>
    </#list>
    <#if keySeq?size == 1>
        <#return groupsHash>
    </#if>
    <#local groups = {}>
    <#list groupsHash?keys as keyVal>
        <#local keyValGroup = groupsHash[keyVal]>
        <#local groups = {keyVal: groupBy(rest(keySeq), keyValGroup)}>
    </#list>
    <#return groups>
</#function>

<#function orderGroups groups>
  <#if groups?is_sequence>
    <#return groups>
  </#if>
  <#local groupKeysSorted = groups?keys?sort>
  <#local orderedGroups = []>
  <#list groupKeysSorted as groupKey>
    <#local orderedGroups = orderedGroups + orderGroups(groups[groupKey])>
  </#list>
  <#return orderedGroups>
</#function>

<#function orderBy keySeq seq>
  <#local key = keySeq?first>
  <#local groups = groupBy(keySeq, seq)>
  <#return orderGroups(groups)>
</#function>

<#function map fun seq>
    <#local mapped = []>
    <#list seq as item>
        <#local mapped = mapped + [fun(item)]>
    </#list>
    <#return mapped>
</#function>

<#function mapcat fun seq>
    <#local mapped = []>
    <#list seq as item>
        <#local mapped = mapped + fun(item)>
    </#list>
    <#return mapped>
</#function>

<#function filter fun seq>
    <#local filtered = []>
    <#list seq as item>
        <#if fun(item)>
            <#local filtered = filtered + [item]>
        </#if>
    </#list>
    <#return filtered>
</#function>

<#assign filterIn = filter>

<#function filterOut fun seq>
    <#local filtered = []>
    <#list seq as item>
        <#if !fun(item)>
            <#local filtered = filtered + [item]>
        </#if>
    </#list>
    <#return filtered>
</#function>

<#function reduce fun seq init=NULL_IND>
  <#if isNulled(init)>
    <#return reduce(fun, rest(seq), first(seq))>
  </#if>
  <#local acc = init>
  <#list seq as item>
    <#local acc = fun(acc, item)>
  </#list>
  <#return acc>
</#function>

<#-- grouped as {importance: X cols: {colA: {importance: Y}} -->
<#function  columnGroups pi=1.0 colname=''>
  <#local ci = columnGroups.importance>
  <#local imps = {}>
  <#if !(columnGroups.cols??)>
    <#return {colname: pi * ci}>
  </#if>
  <#local cols = columnGroups.cols>
  <#list cols?keys as k>
    <#local v = cols[k]>
    <#local subgroup = f(v, pi * ci, k)>
    <#local imps = imps + subgroup>
  </#list>
  <#return imps>
</#function>
