/**
 * https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-6.html
 * https://medium.com/geekculture/implementing-a-type-safe-object-builder-in-typescript-e973f5ecfb9c
 * https://netbasal.com/getting-to-know-the-partial-type-in-typescript-ecfcfbc87cb6
 */


/** All the properties from Target not present in Current */
type Remaining<Target, Current> = Omit<Target, keyof Current>

/** Any subset of remaining properties */
// type NextSupply<T,C,S> = Pick<T, keyof C> & Pick<Partial<T>, keyof S>

// type Coalesced<Target, Current, Supplied> = (
// 		keyof Omit<Remaining<Target, Current>, keyof Supplied> extends never
// 		? Target
// 		: ObjectBuilder<Target, Current & Pick<Target, keyof Supplied>>)

// type ObjectBuilder<Target, Current> = {
// 	supply: ObjectBuilderSupply<Target, Current>
// }

// export function build<T>(): ObjectBuilder<T, Partial<T>> {
// 	return {
// 		supply: <S> (next: S) =>
// 	}
// }

// type ObjectBuilderSupply<Target, Current> = <Supplied> (next: Supplied) => Coalesced<Target, Current, Supplied>


// Test

type TestTarget = { a: string, b: number, c: boolean }

// const test_1: ObjectBuilder<TestTarget, Partial<TestTarget>> = build<TestTarget>();
// const test_2: ObjectBuilder<TestTarget, { b: number, c: boolean }> = test_1.supply({ a: 'butts' });
// const test_3: TestTarget = test_2.supply({ b: 69, c: true })
