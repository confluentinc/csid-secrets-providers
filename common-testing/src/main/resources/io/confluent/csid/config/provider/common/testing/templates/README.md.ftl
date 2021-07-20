# ${input.title}

```bash
confluent-hub install ${input.pluginOwner}/${input.pluginName}:latest
```

${input.introduction}

<#list input.configProviders as configProvider>
## ${configProvider.simpleName}

${configProvider.description}

    <#list configProvider.sections as section>
### ${section.title}

${section.text}

       <#list section.codeBlocks as codeblock>
```${codeblock.language}
${codeblock.text}
```
       </#list>
    </#list>

### Configuration

    <#list configProvider.config.sections as section>

#### ${section.name}

        <#list section.configItems as configItem>
```properties
${configItem.name}
```
${configItem.documentation}

* Type: ${configItem.type}
* Default: ${configItem.defaultValue}
* Valid Values: ${configItem.validator}
* Importance: ${configItem.importance}

        </#list>
    </#list>
</#list>

