package io.confluent.csid.config.provider.aws;

import com.amazonaws.AmazonWebServiceRequest;
import com.amazonaws.services.secretsmanager.model.GetSecretValueRequest;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class AppendSecretPrefixRequestHandler2Test {
    @Test
    public void addsPrefix() {
        String prefix = "test/prefix/";
        String secretId = "primaryId";
        AppendSecretPrefixRequestHandler2 handler = new AppendSecretPrefixRequestHandler2(prefix);
        GetSecretValueRequest request = new GetSecretValueRequest();
        request = request.withSecretId(secretId);

        AmazonWebServiceRequest expected = request.withSecretId(prefix + secretId);
        AmazonWebServiceRequest updated = handler.beforeExecution(request);

        assertEquals(expected, updated);
    }

    @Test
    public void retainsOtherAttributes() {
        String secretId = "primaryId";
        AppendSecretPrefixRequestHandler2 handler = new AppendSecretPrefixRequestHandler2("");
        GetSecretValueRequest request = new GetSecretValueRequest();
        request = request.withSecretId(secretId).withVersionStage("production").withVersionId("v1.2.3");

        AmazonWebServiceRequest updated = handler.beforeExecution(request);

        assertEquals(request, updated);
    }
}