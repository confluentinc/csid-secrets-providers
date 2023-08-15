# What are these files in the sql subdirectory?

These sql files include the SQL statements used to seed an empty database locally, or by the
[cc-postgres](https://github.com/confluentinc/cc-postgres) repo to populate the cpd
mothership db.

## Creating new schemas or tables

You can either edit an existing file in the sql subdirectory to add your changes, or create a separate file.

If you create a new sql file:
* Be sure to also update the [CODEOWNERS](../.github/CODEOWNERS) file to make your team the code-owner for
the new file.
* Once merged, make sure to also run `make update-mk-include` in `cc-postgres`

## Testing changes

You can test changes locally:

- In one terminal

    ```bash
    docker-compose up

    ###
    ### Pay attention to errors in the output
    ###
    ```

- In another terminal

    ```bash
    ### params should match docker-compose file
    
    psql -h localhost -p 5432 --username postgres mothership

    ### when prompted for password, enter: password
    ```

You can also test according to steps in `cc-postgres` repo if you want to test
the k8s job as well.