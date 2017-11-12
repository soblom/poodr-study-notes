# Design Classes with Single Responsibility

Basic Idea (from Chapter 1): You cannot and should not anticipate particular changes in the code. Nobody can do that and if you do, you likely expect the wrong thing. Instead, code should be open to change, whatever in particular it is.

## Organizing Code to Allow for Easy Changes

>Code should be
>
> - **T** ransparent: The consequences of change should be obvious in the code that is changing and in distant code that relies upon it
> - **R** easonable: The cost of any change should be proportional to the benefit the change achieves.
> - **U** sable: Existing code should be usable in new and unexpected contexts
> - **E** xemplary: The code itself should encourage those who change it to perpetuate these qualities.

Acronmy: TRUE


## Creating Classes that have a Single Responsibility

> A class should do the smallest possible useful thing; that is, it should have a single responsibility.


### Example Bike Gears

Bikes have different _gears_ to allow for adjusting to the situation: High speeds with a big gear, high effort (e.g. uphill) in small gears.

**Chainring**: The front part of a chain-operated bike, connecting to the pedals.

**Cog**: The back part of a chain-operated bike, connecting to the back wheel.

Bicyclists use _gear ratio_ to compare differnet gears, based on the ration of _teeth_ between chainring and cog.

**Code Listing 2.1**
```ruby
chainring = 52
cog = 11
ratio = chainring / cog.to_f
puts ratio
# => 4.7272727272727275

chainring = 30
cog = 27
ratio = chainring / cog.to_f
puts ratio
# => 1.1111111111111112
```

_Bycycle_ and _gear_ are nouns, should they become classes? [Something I learned as a heuristic in first semester of CS]. _Bycle_ has no behavior (currently) and should not become a class at this moment.

**Code Listing 2.2**
 ```ruby
 class Gear
   attr_reader :chainring, :cog

   def initialize(chainring, cog)
     @chainring = chainring
     @cog = cog
   end

   def ratio
     chainring / cog.to_f
   end
 end

 puts Gear.new(52, 11).ratio  
 puts Gear.new(30, 27).ratio  
 ```

First Refactoring: Friend has bikes with different wheel sizes and asks that your class accounts for that effect. The concept to capture that is _gear inches_, which is the product of _wheel diamter_ and _gear ratio_, whereas

_wheel diamter = rim diameter + 2 * tire diameter_

**Code Listing 2.3**
```ruby
class Gear
  attr_reader :chainring, :cog, :rim, :tire

  def initialize(chainring, cog, rim, tire)
    @chainring = chainring
    @cog = cog
    @rim = rim
    @tire = tire
  end

  def ratio
    chainring / cog.to_f
  end

  def gear_inches
    ratio * (rim + (2 * tire))
  end
end

puts Gear.new(52, 11, 26, 1.5).gear_inches  
# 137.0909090909091

puts Gear.new(52, 11, 24, 1.25).gear_inches
# 125.27272727272728
```

This class works, but breaks calls to the constructor. The previous call `puts Gear.new(52, 11).ratio` does not work anymore. `Gear` now requires four parameters. So far, we have no other callers and will ignore this.

### Determining If a Class Has a Single Responsibility

**Method 1**: Pretend that the class is sentient and you can interrogate it:

 - "Please Mr. Gear, what is your ratio?" => sounds reasonable.
 - "Please Mr. Gear, what are your gear_inches" => less convincing
 - "Please Mr. Gear, what is your tire(size)" => Doesn't make sense.

 **Method 2**: Describe what a class is doing in one sentence.

  - Sentences shouldn't include _and_ or _or_. In that case, there are likely multiple purposes present.
  - A class where everything is related to one single purpose is described by the word _cohesion_.
  - The _single responsibility principle_, which is behind this idea, comes from Rebecca-Wirfs-Brock and Brian Wilkerson's idea of Responsibility Driven Design.
  - In our example: "Calculate the ration between toothed sprockets"? Or "Calculate the effect a gear has on a bicycle"? In any case, tire is not fitting in that.

### Determining When to Make Design Decisions

Sometimes it is just too early to make the "right" decision. Different variants look equally plausible.

> Do not feel compelled to make design decisions prematurely. Resist, even if you fear your code would dismay the design gurus.

On the other hand:

> Gear lies about your intentions. It is neither usable nor exemplary. It has multiple responsibilities and so should not be reused. It is not a pattern that should be replicated.

[Tension between "good enough" and "be consequent" always exist]

### Writing Code That Embraces Change

**Technique 1: Depend on Behavior, Not Data**

Behaviour resides in the methods and messages.

#### Hide Instance Variables

Hide the variables from everything, even internal methods. Do so by creating accessor methods. Reason: If values will are or will be computed, there is only one place to change it, the accessor method.

**Code Listing 2.4 and 2.5**
=> Simply changes `@cog` and `@chainring` to the respective accessor methods.

Now, if any changes happen to cog, we can change the accessor method.

**Code Listing 2.8**
```ruby
def cog
  @cog * (foo? ? bar_adjustment : baz_adjustment)
end
```

This approach blurs the line between data and behaviour. Is `cog` simply stored information about the cog, or does it represent the process to compute it?

#### Hide Data Structures

Don't depend on complex data structures.

**Code Listing 2.9**
```ruby
class ObscuringReferences
  attr_reader :data
  def initialize(data)
    @data = data
  end

  def diameters
    # 0 is rim, 1 is tire
    data.collect {|cell|
       cell[0] + (cell[1] * 2)}
   end
   # ... many other methods that index into the array
 end
```

The "data" is a two-dimensional array, each entry representing one wheel:

**Code Listing 2.10**
```ruby
@data = [[622, 20], [622, 23], [559, 30], [559, 40]]
```

Even if `@data` is wrapped in an accessor, it exposes the full complexity of this data structure. Any method using `@data` needs to encode knowledge about its implementation (an array with `0` for rim and `1` for tire).

The solution is to use a Struct, to built meaning into the structure.

**Code Listing 2.11**
```ruby
class RevealingReferences
 attr_reader :wheels
 def initialize(data)
   @wheels = wheelify(data)
 end

 def diameters
   wheels.collect {|wheel|
     wheel.rim + (wheel.tire * 2)}
  end
  # ... now everyone can send rim/tire to wheel

  Wheel = Struct.new(:rim, :tire)
  def wheelify(data)
    data.collect {|cell|
      Wheel.new(cell[0], cell[1])}
  end
end
```

In effect, the Struct is a "little" object. `wheelify` is the only place that knows how to turn `data` into a `wheel`.
