<#ftl nsPrefixes={"D":"http://docbook.org/ns/docbook"}>

<#import "util.ftl" as u>

<#import "node-handlers.ftlh" as defaultNodeHandlers>
<#import "customizations.ftlh" as customizations>
<#assign nodeHandlers = [customizations, defaultNodeHandlers]>

<#macro navigationBar top>
  <#local captured>
    <#if showNavigationBar>
      <#if top>
        <#--><@pagers />-->
        <@bookmarks />
      <#else>
        <@pagers />
      </#if>
    </#if>
  </#local>
  <#if captured?trim?length == 0>
    <#if !top>
      <div class="missingNavigationFooterLine"></div>
    </#if>
  <#else>
    <div class="navigation">
      <#-- keep site-width inside navigation so that the background extends -->
      <div class="site-width">
        ${captured?noEsc}<#t>
      </div>
    </div>
  </#if>
</#macro>

<#macro breadcrumb>
  <#if !showBreadCrumb>
    <#return>
  </#if>
  <#local path = []>
  <#local curNode = .node>
  <#list 1.. as _>
    <#local path = [curNode] + path>
    <#if curNode.@docgen_root_element?size != 0>
      <#break>
    </#if>
    <#local curNode = curNode?parent>
  </#list>
  <#if (path?size > 1)>
    <ul class="breadcrumb" itemscope itemtype="http://schema.org/BreadcrumbList"><#t>
      <#list path as step>
        <li class="step-${step?index}" itemprop="itemListElement" itemscope itemtype="http://schema.org/ListItem"><#t>
          <a class="label" itemprop="item" href="${CreateLinkFromNode(step)}"><#t>
            <span itemprop="name"><#recurse u.getRequiredTitleElement(step) using nodeHandlers></span><#t>
          </a><#t>
        </li><#t>
      </#list>
    </ul><#t>
  <#else>
    <ul class="breadcrumb" itemscope itemtype="http://schema.org/BreadcrumbList"><#t>
      <li class="step-0" itemprop="itemListElement" itemscope itemtype="http://schema.org/ListItem"><#t>
        <span itemprop="name">Table of Contents</span><#t>
      </li><#t>
    </ul><#t>
  </#if>
</#macro>


<#macro breadcrumbJs>
  <#outputFormat "plainText">
    var breadcrumb = [<#t>
    <#local path = []>
    <#local curNode = .node>
    <#list 1.. as _>
      <#local path = [curNode] + path>
      <#if curNode.@docgen_root_element?size != 0>
        <#break>
      </#if>
      <#local curNode = curNode?parent>
    </#list>
    <#if (path?size > 1)>
      <#list path as step>
        "${u.titleToString(step.title[0]!step.info.title)?jsString}"<#t>
        <#sep>,<#t>
      </#list>
    </#if>
    ];<#t>
  </#outputFormat>
</#macro>


<#macro bookmarks>
  <#if internalBookmarks?size != 0 || externalBookmarks?size != 0>
    <div class="bookmarks" title="Bookmarks"><#t>
        <span class="sr-only">Bookmarks:</span><#t>
        <ul class="bookmark-list"><#t>
          <#local curHref = CreateLinkFromNode(.node)>
          <#list internalBookmarks?keys as k>
            <li><#t>
              <#local target = CreateLinkFromID(internalBookmarks[k])>
              <#if target != curHref>
                <a href="${target}">${k}</a><#t>
              <#else>
                ${k}<#t>
              </#if>
            </li><#t>
          </#list>
          <#list externalBookmarks?keys as k>
            <li><#t>
              <a href="${externalBookmarks[k]}">${k}</a><#t>
            </li><#t>
          </#list>
        </ul><#t>
    </div><#t>
  </#if>
</#macro>


<#macro tabs>
    <#local tabs = .dataModel.tabs>
    <#if tabs?size != 0>
        <ul class="tabs"><#t>
            <#list tabs?keys as tabTitle>
                <#if tabs[tabTitle] != ''>
                    <#-- @todo: need hook for dynamically setting external links -->
                    <li><#t>
                      <a<#if tabTitle == "Java API"> class="external"</#if> href="${tabs[tabTitle]}">${tabTitle}</a><#t>
                    </li><#t>
                <#else>
                    <li class="current"><#t>
                      <a href="index.html">${tabTitle}</a><#t>
                    </li><#t>
                </#if>
            </#list>
        </ul><#t>
    </#if>
</#macro>

<#macro pagers class="">
  <#-- Render pager panel only if it's not a single-HTML-file output: -->
  <#if nextFileElement?? || previousFileElement?? || parentFileElement??>
    <div class="${('pagers ' + class)?trim}"><#t>
      <@pagerButton text="Previous" element=previousFileElement! class="previous" /><#t>
      <@pagerButton text="Next" element=nextFileElement! class="next" /><#t>
    </div><#t>
  </#if>
</#macro>


<#macro pagerButton text element class>
  <#compress>
    <#if element?hasContent>
      <#local href = CreateLinkFromNode(element)>
      <a class="paging-arrow ${class}" href="${href}"><span>${text}</span></a><#t>
    <#else>
      <span class="paging-arrow disabled ${class}"><span>${text}</span></span><#t>
    </#if>
  </#compress>
</#macro>

