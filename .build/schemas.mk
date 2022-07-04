# JSON Schema source generation

SCHEMAS_JSON := $(wildcard src/lib/json/*.schema.json)
SCHEMAS_CODE := $(foreach schema,${SCHEMAS_JSON},${schema:.json=.ts})
define SCHEMAS_GEN =
schemas: ${2}
${2}: ${1}
	npx json2ts \
		--input  $${<} \
		--output $${@} \
		--cwd $$(dir $${<})
endef


schemas:

$(foreach schema,${SCHEMAS_JSON},\
	$(eval $(call SCHEMAS_GEN,${schema},${schema:.json=.ts})))
