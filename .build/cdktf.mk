# CDKTF operations.

synth:
	npx cdktf synth

plan-%:
	npx cdktf diff $(word 2,${@:-= })
