package io.confluent.csid.config.provider.aws;

import com.amazonaws.auth.AWSCredentialsProvider;
import com.amazonaws.auth.AWSStaticCredentialsProvider;
import com.amazonaws.handlers.RequestHandler2;
import com.amazonaws.services.secretsmanager.AWSSecretsManagerClientBuilder;
import com.google.common.collect.ImmutableMap;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;

class SecretsManagerFactoryImplTest  {
    private AWSSecretsManagerClientBuilder builderWithConfig(Map<String, ?> settings) {
        SecretsManagerConfigProviderConfig config = new SecretsManagerConfigProviderConfig(settings);
        SecretsManagerFactoryImpl factory = new SecretsManagerFactoryImpl();
        return factory.configure(config);
    }

    @Test
    public void addsRegion() {
        String region = "eu-west-1";
        Map<String, ?> settings = ImmutableMap.of("aws.region", region);

        AWSSecretsManagerClientBuilder builder = builderWithConfig(settings);

        assertEquals(region, builder.getRegion());
    }

    @Test
    public void addsCredentials() {
        String expectedAccessKey = "test_access_key";
        String expectedSecretKey = "some_test_key";
        Map<String, ?> settings = ImmutableMap.of("aws.access.key", expectedAccessKey, "aws.secret.key.id", expectedSecretKey);

        AWSSecretsManagerClientBuilder builder = builderWithConfig(settings);

        AWSCredentialsProvider credentialsProvider = builder.getCredentials();
        assertInstanceOf(AWSStaticCredentialsProvider.class, credentialsProvider);
    }

    @Test
    public void addsPrefixHandler() {
        Map<String, ?> settings = ImmutableMap.of("secret.prefix", "test/prefix/");

        AWSSecretsManagerClientBuilder builder = builderWithConfig(settings);

        List<RequestHandler2> requestHandlers = builder.getRequestHandlers();
        assertEquals(1, requestHandlers.size());
        assertInstanceOf(AppendSecretPrefixRequestHandler2.class, requestHandlers.get(0));
    }
}
