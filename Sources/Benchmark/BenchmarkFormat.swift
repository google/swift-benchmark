import ArgumentParser

public enum BenchmarkFormat: String, ExpressibleByArgument {
    case console
    case json
}
