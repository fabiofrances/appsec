import { WebTracerProvider } from '@opentelemetry/sdk-trace-web'
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-web'
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http'
import { FetchInstrumentation } from '@opentelemetry/instrumentation-fetch'
import { registerInstrumentations } from '@opentelemetry/instrumentation'
import { Resource } from '@opentelemetry/resources'

const provider = new WebTracerProvider({
  resource: new Resource({ 'service.name': 'bmi-frontend' }),
  spanProcessors: [
    new BatchSpanProcessor(
      new OTLPTraceExporter({ url: '/otel/v1/traces' }),
    ),
  ],
})

provider.register()

registerInstrumentations({
  instrumentations: [
    new FetchInstrumentation({
      propagateTraceHeaderCorsUrls: [/.*/],
    }),
  ],
})
