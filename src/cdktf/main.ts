/**
 * Notes:
 * | returns | argument | context |
 * | ------: | :------: | :-----: |
 * |  result |   let    |   run   |
 * |    this |   also   |  apply  |
 */
import { App } from 'cdktf'
import { ValheimEcs } from './valheim-ecs'
import 'scope-extensions-js'

new App()
		.also(app => new ValheimEcs(app))
		.synth()
