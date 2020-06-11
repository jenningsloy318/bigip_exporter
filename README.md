# BIG-IP exporter
Prometheus exporter for BIG-IP statistics. Uses iControl REST API.

based on https://github.com/ExpressenAB/bigip_exporter, I add support multi-instance monitoring, inspired by mysqld_exporter and ipmi_exporter, to rewirte bigip_exporter.go and config.go.

## Get it
The latest version is 1.0.0. All releases can be found under [Releases](https://github.com/ExpressenAB/bigip_exporter/releases) and docker images are available at [Docker Hub](https://hub.docker.com/r/expressenab/bigip_exporter/tags/)(Thanks to [0x46616c6b](https://github.com/0x46616c6b)).

## Usage
The bigip_exporter is easy to use. Example:
```
./bigip_exporter  --config.file="bigip_exporter.yml"
```
bigip_exporter.yml:
```yml
credentials:
    default:
        user: "USER"
        pass: "password"
        basic_auth: "false"
```

then you can get the metrics via 
```shell
curl localhost:9142/bigip?target=<bigip_host>:443
```

prometheus job config:
```yaml

- job_name: "bigip-exporter"
  scrape_interval: 1m
  scrape_timeout: 30s
  metrics_path: /bigip
  scheme: http
  file_sd_configs:
  - files:
    - 'tgroups/bigip.yml'
    refresh_interval: 5m
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: 10.36.48.46:9142

```
#### Configuration file
Take a look at this [example configuration file](https://github.com/jenningsloy318/bigip_exporter/blob/master/bigip_exporter.yml)

## Implemented metrics
* Virtual Server
* Rule
* Pool
* Node

## Prerequisites
* User with read access to iControl REST API

## Tested versions of iControl REST API
Currently only version 12.0.0 and 12.1.1 are tested. If you experience any problems with other versions, create an issue explaining the problem and I'll look at it as soon as possible or if you'd like to contribute with a pull request that would be greatly appreciated.


**13.0 is not supported now**

## Building

just you can build with `make build`
## Possible improvements
### Gather data in the background
Currently the data is gathered when the `/metrics` endpoint is called. This causes the request to take about 4-6 seconds before completing. This could be fixed by having a go thread that gathers data at regular intervals and that is returned upon a call to the `/metrics` endpoint. This would however go against the [guidelines](https://prometheus.io/docs/instrumenting/writing_exporters/#scheduling).
