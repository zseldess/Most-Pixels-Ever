// Examples of using .ini FileParser class

import mpe.config.*;

FileParser sketch_fp;

sketch_fp = new FileParser(sketchPath("sketch.ini"));

println("Int: " + sketch_fp.getIntValue("Int"));
println("Float: " + sketch_fp.getFloatValue("Float"));
println("String: " + sketch_fp.getStringValue("String"));
println("Int Array: " + Arrays.toString(sketch_fp.getIntValues("IntArray")));
println("Float Array: " + Arrays.toString(sketch_fp.getFloatValues("FloatArray")));
println("String Array: " + Arrays.toString(sketch_fp.getStringValues("StringArray")));

// try some that don't exist
println("Int: " + sketch_fp.getIntValue("Int2"));
println("Float: " + sketch_fp.getFloatValue("Float2"));
println("String: " + sketch_fp.getStringValue("String2"));
println("Int Array: " + Arrays.toString(sketch_fp.getIntValues("IntArray2")));
println("Float Array: " + Arrays.toString(sketch_fp.getFloatValues("FloatArray2")));
println("String Array: " + Arrays.toString(sketch_fp.getStringValues("StringArray2")));




