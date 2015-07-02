<#ftl nsPrefixes={"D":"http://docbook.org/ns/docbook"} stripText = true>

<#import "util.ftl" as u>
<#import "footer.ftl" as footer>
<#import "header.ftl" as header>
<#import "navigation.ftl" as nav>
<#import "google.ftl" as google>
<#import "node-handlers.ftl" as defaultNodeHandlers>
<#import "customizations.ftl" as customizations>
<#assign nodeHandlers = [customizations, defaultNodeHandlers]>

<@page>
  <@head />

  <body itemscope itemtype="http://schema.org/Article"><#lt>
    <@browserWarning />
    <@header.header />
    <div class="main-content site-width">
      <div class="content-wrapper<#if disableJavaScript> no-toc</#if>">
        <@dynamicToc />
        <@pageContent />
      </div>
    </div>
    <@footer.footer />
  </body><#lt>
</@page>


<#macro head>
  <#assign titleElement = u.getRequiredTitleElement(.node)>
  <#assign title = u.titleToString(titleElement)>
  <#local topLevelTitle = u.getRequiredTitleAsString(.node?root.*)>
  <#assign pageTitle = topLevelTitle />
  <#if title != topLevelTitle>
    <#assign pageTitle = title + " - " + topLevelTitle>
  </#if>
  <#compress>
    <head prefix="og: http://ogp.me/ns#">
      <meta charset="utf-8">
      <title>${pageTitle?html?replace("&#39;", "'")}</title>

      <@metaTags siteName=topLevelTitle title=title?html?replace('&#39;', '\'') />
      <@canonicalUrl />

      <link rel="icon" href="favicon.png" type="image/png"><#-- @todo: pull this in dynamically -->
      <@css />

      <#if !offline && onlineTrackerHTML??>
        ${onlineTrackerHTML}
      </#if>
    </head>
  </#compress>
</#macro>


<#macro metaTags siteName title>
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta name="format-detection" content="telephone=no">
  <meta property="og:site_name" content="${siteName?html}">
  <meta property="og:title" content="${title?html?replace('&#39;', '\'')}">
  <meta property="og:locale" content="en_US">
</#macro>


<#macro canonicalUrl>
  <#-- @todo: improve this logic -->
  <#assign nodeId = .node.@id>
  <#if nodeId == "autoid_1">
    <#assign nodeId = "index">
  </#if>

  <#if deployUrl??>
    <#local canonicalUrl = "${deployUrl + nodeId}.html">
    <meta property="og:url" content="${canonicalUrl}">
    <link rel="canoical" href="${canonicalUrl}">
  </#if>
</#macro>


<#macro css>
  <#if !offline>
    <link rel="stylesheet" type="text/css" href="http://fonts.googleapis.com/css?family=Roboto:500,700,400,300|Droid+Sans+Mono"><#lt>
  </#if>
  <link rel="stylesheet" type="text/css" href="docgen-resources/docgen.min.css"><#lt>
</#macro>


<#macro browserWarning>
  <!--[if lte IE 9]>
  <div style="background-color: #C00; color: #fff; padding: 12px 24px;">Please use a modern browser to view this website.</div>
  <![endif]--><#rt>
</#macro>


<#macro page>
  <!doctype html><#lt>
  <html lang="en" class="page-type-${getPageType()?replace(':', '-')?replace('_', '-')}"><#lt>
    <#nested>
  </html><#lt>
</#macro>


<#macro dynamicToc>
  <div id="table-of-contents-wrapper" class="col-left">
    <#-- table of contents generated by js -->
    <#-- execute immediately to prevent page jerking -->
    <#if !disableJavaScript>
      <script><@nav.breadcrumbJs /></script>
      <script src="toc.js"></script>
      <script src="docgen-resources/main.min.js"></script>
    </#if>
  </div>
</#macro>

<#macro pageContent>
  <#local pageType = getPageType()>
  <div class="col-right"><#t>
    <div class="page-content"><#t>
      <#compress>
        <div class="page-title"><#t>
          <#if !simpleNavigationMode>
            <@nav.pagers class="top" /><#t>
          </#if>
          <div class="title-wrapper"><#t>
            <#visit titleElement using nodeHandlers><#t>
          </div><#t>
        </div><#t>
      </#compress>
      <#-- - Render either ToF (Table of Files) or Page ToC; -->
      <#--   both are called, but at least one of them will be empty: -->
      <#if pageType == "docgen:search_results">
        <@google.searchResults />
      <#elseIf pageType == "index" || pageType == "glossary">
        <#visit .node using nodeHandlers>
      <#elseIf pageType == "docgen:detailed_toc">
        <@toc att="docgen_detailed_toc_element" maxDepth=99 /><#t>
      <#else>
        <@toc att="docgen_file_element" maxDepth=maxTOFDisplayDepth /><#t>
        <@toc att="docgen_page_toc_element" maxDepth=99 minLength=2 /><#t>
        <#-- - Render the usual content, like <para>-s etc.: -->
        <#list .node.* as child>
          <#if child.@docgen_file_element?size == 0
              && child?nodeName != "title"
              && child?nodeName != "subtitle"
              && child?nodeName != "info">
            <#visit child using nodeHandlers>
          </#if>
        </#list>
      </#if>
      <@footnotes />
      <#if !simpleNavigationMode>
        <div class="bottom-pagers-wrapper"><#t>
          <@nav.pagers class="bottom" /><#t>
        </div><#t>
      </#if>
    </div><#t>
  </div><#t>
</#macro>


<#macro footnotes>
  <#-- Render footnotes, if any: -->
  <#local footnotes = defaultNodeHandlers.footnotes>
  <#if footnotes?size != 0>
    <div id="footnotes">
      Footnotes:
      <ol>
        <#list footnotes as footnote>
          <li><a name="autoid_footnote_${footnote?counter}"></a>${footnote}</li>
        </#list>
      </ol>
    </div>
  </#if>
</#macro>


<#macro toc att maxDepth minLength=1>
  <#compress>
    <#local tocElems = .node["*[@${att}]"]>
    <#if (tocElems?size >= minLength)>
        <@toc_inner tocElems=tocElems att=att maxDepth=maxDepth curDepth=1 /><#t>
    </#if>
  </#compress>
</#macro>


<#macro toc_inner tocElems att maxDepth curDepth=1>
  <#compress>
    <#if tocElems?size == 0><#return></#if>

    <#if curDepth == 1>
      <#local class = "page-menu">
    </#if>

    <ul<#if class?hasContent> class="${class?trim}"</#if>><#t>
      <#list tocElems as tocElem>
        <li><#t>
          <a class="page-menu-link" href="${CreateLinkFromID(tocElem.@id)?html}" data-menu-target="${tocElem.@id}"><#t>
            <#recurse u.getRequiredTitleElement(tocElem) using nodeHandlers><#t>
          </a><#t>
          <#if (curDepth < maxDepth)>
            <@toc_inner tocElem["*[@${att}]"], att, maxDepth, curDepth + 1 /><#t>
          </#if>
        </li><#t>
      </#list>
    </ul><#t>
  </#compress>
</#macro>

<#function getPageType>
  <#return pageType!.node?nodeName>
</#function>
