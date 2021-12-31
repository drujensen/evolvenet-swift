import Foundation

class Synapse {
    let index: Int
    var weight: Double = 0.0

    init(index: Int, weight: Double) {
        self.index = index
        self.weight = weight
    }

    func clone() -> Synapse {
        let synapse = Synapse(index: self.index, weight: self.weight)
        return synapse
    }

    func randomize() {
        self.weight = Double.random(in: -1..<1)
    }

    func mutate(rate: Double) {
        self.weight += Double.random(in: -rate..<rate)
    }

    func punctuate(pos: Int) {
        let precision: Double = Double(truncating: pow(10.0, pos) as NSNumber)
        self.weight = round(self.weight * precision) / precision
    }
}

class Neuron {
    var synapses: [Synapse] = []
    let function: String
    var activation: Double = 0.0
    var bias: Double = 0.0

    init(function: String) {
        self.function = function
    }

    func clone() -> Neuron {
        let neuron = Neuron(function: self.function)
        neuron.activation = self.activation
        neuron.bias = self.bias
        for synapse in self.synapses {
            neuron.synapses.append(synapse.clone())
        }
        return neuron
    }

    func randomize() {
        self.bias = Double.random(in: -1..<1)
        for synapse in self.synapses {
            synapse.randomize()
        }
    }

    func mutate(rate: Double) {
        self.bias += Double.random(in: -rate..<rate)
        let synapse_rate = rate / Double(self.synapses.count)
        for synapse in self.synapses {
            synapse.mutate(rate: synapse_rate)
        }
    }

    func punctuate(pos: Int) {
        let precision: Double = Double(truncating: pow(10.0, pos) as NSNumber)
        self.bias = round(self.bias * precision) / precision
        for synapse in self.synapses {
            synapse.punctuate(pos: pos)
        }
    }

    func activate(value: Double) {
        self.activation = value
    }

    func activate(parent: Layer) {
        var sum: Double = 0.0
        for synapse in self.synapses {
            sum += (synapse.weight * parent.neurons[synapse.index].activation)
        }
        sum += self.bias
        switch self.function {
            case "relu":
                self.activation = sum < 0.0 ? 0.0 : sum
            case "signoid":
                self.activation = (1.0/(1.0 + pow(M_E, -sum)))
            case "tanh":
                self.activation = (pow(M_E, sum) - pow(M_E, -sum)) / (pow(M_E, sum) + pow(M_E, -sum))
            default:
                self.activation = sum
        }
    }
}

class Layer {
    var neurons: [Neuron] = []
    var size: Int
    let function: String
    var parent: Layer? = nil

    init(size: Int, function: String = "signoid") {
        self.size = size
        self.function = function
        for _ in (0..<size) {
            self.neurons.append(Neuron(function: function))
        }
    }

    func connect(parent optParent: Layer?) {
        if let parent = optParent {
            self.parent = parent
            for neuron in self.neurons {
               for index in (0..<parent.neurons.count) {
                   neuron.synapses.append(Synapse(index: index, weight: 0.0))
               }
            }
        }
    }

    func clone() -> Layer {
        let layer = Layer(size: 0, function: self.function)
        layer.size = self.neurons.count
        for neuron in self.neurons {
            layer.neurons.append(neuron.clone())
        }
        return layer
    }

    func randomize() {
        for neuron in self.neurons {
            neuron.randomize()
        }
    }

    func mutate(rate: Double) {
        let neuronRate = rate / Double(self.neurons.count)
        for neuron in self.neurons {
            neuron.mutate(rate: neuronRate)
        }
    }

    func punctuate(pos: Int) {
        for neuron in self.neurons {
            neuron.punctuate(pos: pos)
        }
    }

    func activate(data: [Double]) {
        for index in (0..<self.neurons.count) {
            let neuron = self.neurons[index]
            neuron.activate(value: data[index])
        }
    }

    func activate(parent: Layer) {
        for neuron in self.neurons {
            neuron.activate(parent: parent)
        }
    }
}

class NeuralNetwork: Network {
    var layers: [Layer] = []
    var error: Double = 1.0

    func push(layer: Layer) {
        self.layers.append(layer)
    }

    func connect() {
        var parent: Layer? = nil
        for layer in layers {
            layer.connect(parent: parent)
            parent = layer
        }
    }

    func clone() -> Network {
        let network = NeuralNetwork()
        for layer in self.layers {
            network.layers.append(layer.clone())
        }
        return network
    }

    func randomize() -> Network {
        self.error = 1.0
        for layer in self.layers {
            layer.randomize()
        }
        return self
    }

    func mutate() {
        for layer in self.layers {
            layer.mutate(rate: self.error)
        }
    }

    func punctuate(pos: Int) {
        for layer in self.layers {
            layer.punctuate(pos: pos)
        }
    }

    func run(data: [Double]) -> [Double] {
        for layer in self.layers {
            if let parent = layer.parent {
                layer.activate(parent: parent)
            } else {
                layer.activate(data: data)
            }
        }
        return self.layers.last!.neurons.map { neuron in neuron.activation }
    }

    func evaluate(data: [[[Double]]]) {
        var sum: Double = 0.0
        for row in data {
            let expected = row[1]
            let actual = run(data: row[0])
            for index in (0..<expected.count) {
                let exp = expected[index]
                let act = actual[index]
                let diff = exp - act
                sum += diff * diff
            }
        }
        self.error = sum / Double(2 * data.count)
    }
}