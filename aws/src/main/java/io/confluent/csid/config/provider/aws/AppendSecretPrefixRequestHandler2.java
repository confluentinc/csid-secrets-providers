package io.confluent.csid.config.provider.aws;

import com.amazonaws.AmazonWebServiceRequest;
import com.amazonaws.handlers.RequestHandler2;
import com.amazonaws.services.secretsmanager.model.GetSecretValueRequest;

class AppendSecretPrefixRequestHandler2 extends RequestHandler2 {
    private final String prefix;

    public AppendSecretPrefixRequestHandler2(String prefix) {
        this.prefix = prefix;
    }

    @Override
    public AmazonWebServiceRequest beforeExecution(AmazonWebServiceRequest request) {
        GetSecretValueRequest local = ((GetSecretValueRequest) request);
        local.setSecretId(prefix + local.getSecretId());
        return local;
    }
}
